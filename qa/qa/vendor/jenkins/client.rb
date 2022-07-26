# frozen_string_literal: true

require 'base64'
require 'cgi'
require 'fileutils'
require 'json'
require 'nokogiri'
require 'rest-client'
require 'securerandom'

require_relative './helpers'
require_relative './job'

module QA
  module Vendor
    module Jenkins
      NetworkError = Class.new(StandardError)
      NotParseableError = Class.new(StandardError)
      class Client
        include Helpers

        attr_accessor :cookies

        DEFAULT_SERVER_PORT = 8080

        # @param host [String] the ip or hostname of the jenkins server
        # @param user [String] the Jenkins admin user
        # @param password [String] the Jenkins admin password
        # @param port [Integer] the port that Jenkins is serving on
        def initialize(host, user:, password:, port: nil)
          @host = host
          @user = user
          @password = password
          @port = port
          @cookies = {}
        end

        def ready?
          !!try_parse(RestClient.get(crumb_path, auth_headers).body)
        end

        # Creates a new job in Jenkins
        #
        # @param name [String] the name of the job
        # @yieldparam job [Jenkins::Job] the job to be configured
        # @return [Jenkins::Job] the created job in Jenkins
        def create_job(name)
          job = Job.new(name, self)
          yield job if block_given?
          job.create
          job
        end

        # Is a given job running?
        #
        # @param name [String] the name of the job
        # @return [Boolean] is the job running?
        def job_running?(name)
          res = execute <<~GROOVY
            project = Jenkins.instance.getProjects().find{p -> p.getName().equals('#{name}')}
            build = project.getBuilds().find{b -> b.getExecutor()}
            return build ? build.getExecutor().isActive() : false
          GROOVY
          JSON.parse parse_result(res)
        end

        # Number of builds currently executing for a given job
        #
        # @param name [String] the name of the job
        # @return [Integer] the number of builds currently running
        def number_of_jobs_running(name)
          res = execute <<~GROOVY
            project = Jenkins.instance.getProjects().find{p -> p.getName().equals('#{name}')}
            builds = project.getBuilds().findAll{b -> b.getExecutor()}
            return builds.size
          GROOVY
          JSON.parse parse_result(res)&.to_i
        end

        # Latest build status for a job
        #
        # @param name [String] the name of the job
        # @return [Symbol] the latest build status eg, (:success, :failure, etc)
        def last_build_status(name)
          res = execute <<~GROOVY
            project = Jenkins.instance.getProjects().find{p -> p.getName().equals('#{name}')}
            build = project.getBuilds()[-1]
            return build.getResult()
          GROOVY
          parse_result(res)&.downcase&.to_sym
        end

        # Latest build id for a job
        # Can be used to reference in other queries
        #
        # @param job_name [String] the name of the job
        # @return [Integer] the latest build id
        def last_build_id(job_name)
          res = execute <<~GROOVY
            project = Jenkins.instance.getProjects().find{p -> p.getName().equals('#{job_name}')}
            build = project.getBuilds()[-1]
            return build.getId()
          GROOVY
          parse_result(res)&.to_i
        end

        # Latest build log for a job
        #
        # @param job_name [String] the name of the job
        # @param start [Integer] the log offset to return
        # @return [String] the latest Jenkins log/output for this job
        def last_build_log(job_name, start = 0)
          get(
            path: "/job/#{job_name}/#{last_build_id(job_name)}/logText/progressiveText",
            params: { start: start }
          ).body
        end

        # Triggers a build for a given job
        #
        # @param name [String] the name of the job to trigger a build for
        # @param [Hash] params the query parameters as a hash for the build endpoint
        def build(name, params: {})
          post(params, path: "/job/#{name}/build")
        end

        # Executes a Groovy script against the Jenkins instance
        #
        # @param script [String] the Groovy script to execute
        def execute(script)
          post("script=#{script}", path: '/scriptText')
        end

        # Sends XML to a given Jenkins endpoint
        # This might be useful for filling in gaps in this lib
        #
        # @param xml [String] the xml to post
        # @param params [Hash] the query parameters as a hash
        # @param path [String] the path to post to ex: /job/<name>/build
        # @return [Typhoeus::Response]
        def post_xml(xml, params: {}, path: '')
          post(xml, params: params, path: path, headers: { 'Content-Type' => 'text/xml' })
        end

        # Posts data to Jenkins
        # This might be useful for filling in gaps in this lib
        #
        # @param data [String | Hash] the xml to post
        # @param params [Hash] the query parameters as a hash
        # @param path [String] the path to post to ex: /job/<name>/build
        # @param headers [Hash] additional headers to send
        # @return [Typhoeus::Response]
        def post(data, params: {}, path: '', headers: {})
          get_crumb
          RestClient.post(
            "#{api_path}#{path}?#{params_to_s(params)}",
            data,
            headers.merge(full_headers)
          )
        end

        # Gets from a Jenkins endpoint
        # This might be useful for filling in gaps in this lib
        #
        # @param path [String] the path to get from ex: /job/<name>/builds/<build_id>/logText/progressiveText
        # @param params [Hash] the query parameters as a hash
        # @return [Typhoeus::Response]
        def get(path: '', params: {})
          get_crumb
          RestClient.get(
            "#{api_path}#{path}?#{params_to_s(params)}",
            full_headers
          )
        end

        # configures the Jenkins GitLab plugin
        #
        # @param url [String] the url for the GitLab instance
        # @param access_token [String] an access token for the GitLab instance
        # @param secret_id [String] an secret id used for the Jenkins GitLab credentials
        # @param hargs [Hash] extra keyword arguments to provide
        # @option hargs [String] :connection_name the name to use for the gitlab connection
        # @option hargs [Integer] :read_timeout the read timeout for GitLab Jenkins
        # @option hargs [Integer] :connection_timeout the connection timeout for GitLab Jenkins
        # @option hargs [Boolean] :ignore_ssl_errors whether GitLab Jenkins should ignore SSL errors
        # @return [String] the execute response from Jenkins
        def configure_gitlab_plugin(url, access_token:, secret_id: SecureRandom.hex(4), **hargs)
          configure_secret(access_token, secret_id)
          configure_gitlab(url, secret_id, **hargs)
        end

        private

        def parse_result(res)
          check_network_error(res)

          res.body.scan(/Result: (.*)/)&.dig(0, 0)
        end

        def configure_gitlab(
          url,
          secret_id,
          connection_name: 'default',
          read_timeout: 10,
          connection_timeout: 10,
          ignore_ssl_errors: true
        )
          res = execute <<~GROOVY
            import com.dabsquared.gitlabjenkins.connection.*;
            conn = new GitLabConnection(
              "#{connection_name}",
              "#{url}",
              "#{secret_id}",
              #{ignore_ssl_errors},
              #{connection_timeout},
              #{read_timeout}
            );

            config = GitLabConnectionConfig.get();
            config.setConnections([conn]);
          GROOVY
          res.body
        end

        def configure_secret(access_token, credential_id)
          execute <<~GROOVY
            import jenkins.model.Jenkins;
            import com.cloudbees.plugins.credentials.domains.Domain;
            import org.jenkinsci.plugins.plaincredentials.impl.StringCredentialsImpl;
            import com.cloudbees.plugins.credentials.CredentialsScope;
            import hudson.util.Secret;

            instance = Jenkins.instance;
            domain = Domain.global();
            store = instance.getExtensionList("com.cloudbees.plugins.credentials.SystemCredentialsProvider")[0].getStore();

            secretText = new StringCredentialsImpl(
              CredentialsScope.GLOBAL,
              "#{credential_id}",
              "GitLab API Token",
              Secret.fromString("#{access_token}")
            );

            store.addCredentials(domain, secretText);
          GROOVY
        end

        def get_crumb
          return if @crumb

          response = RestClient.get(crumb_path, auth_headers)
          response_body = handle_json_response(response)
          @crumb = response_body['crumb']
        end

        def params_to_s(params)
          params.each_with_object([]) do |(k, v), memo|
            memo << "#{k}=#{v}"
          end.join('&')
        end

        def full_headers
          crumb_headers
            .merge(auth_headers)
            .merge(cookie_headers)
        end

        def crumb_headers
          { 'Jenkins-Crumb' => @crumb }
        end

        def auth_headers
          { 'Authorization' => "Basic #{userpwd}" }
        end

        def cookie_headers
          { cookies: @cookies }
        end

        def userpwd
          Base64.encode64("#{@user}:#{@password}")
        end

        def api_path
          "http://#{@host}:#{port}"
        end

        def crumb_path
          "#{api_path}/crumbIssuer/api/json"
        end

        def port
          @port || DEFAULT_SERVER_PORT
        end
      end
    end
  end
end
