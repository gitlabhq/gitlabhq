# frozen_string_literal: true

module QA
  module Vendor
    module Jenkins
      class Job
        include Helpers

        REQUIRED_BUILD_FIELDS = %i[name description shell_command].freeze

        attr_accessor(
          :name,
          :description,
          :keep_deps,
          :can_roam,
          :disabled,
          :repo_url,
          :gitlab_connection,
          :shell_command
        )

        # Prefer Jenkins::Client#jobs and Jenkins::Client.create_job over this constructor
        #
        # @param name [String] the name of the job
        # @param client [Jenkins::Client] the jenkins client
        def initialize(name, client)
          @name = name
          @client = client
        end

        # Saves the Job in Jenkins
        def create
          validate_required_fields!

          response = @client.post_xml(build, path: '/createItem', params: { name: name })

          check_network_error(response)
          response.body
        end

        # Triggers a build for the job
        def run
          @client.build(@name)
        end

        # Returns the jobs last build status
        def status
          @client.last_build_status(@name)
        end

        # Returns the jobs last log
        #
        # @param start [Integer] the log offset to query
        def log(start: 0)
          @client.last_build_log(@name, start)
        end

        # Returns whether the job is running
        #
        # @return [Boolean]
        def running?
          @client.job_running?(@name)
        end

        # Returns the count of active builds
        #
        # @return [Integer]
        def active_runs
          @client.number_of_jobs_running(@name)
        end

        private

        def validate_required_fields!
          error = REQUIRED_BUILD_FIELDS.each_with_object("") do |field, memo|
            memo << "#{field} is required\n" unless send(field)
          end
          raise ArgumentError, error unless error.empty?
        end

        def build
          builder = Nokogiri::XML::Builder.new(encoding: 'UTF-8') do |xml|
            xml.project do
              xml.actions
              xml.description description
              xml.keepDependencies false
              xml.properties do |props|
                build_gitlab_connection(props)
              end
              xml.canRoam true
              xml.disabled false
              xml.blockBuildWhenDownstreamBuilding false
              xml.blockBuildWhenUpstreamBuilding false
              xml.triggers do |triggers|
                build_gitlab_triggers(triggers)
              end
              xml.concurrentBuild false
              xml.builders do
                xml.send(:"hudson.tasks.Shell") do
                  xml.command shell_command
                  xml.configuredLocalRules
                end
              end
              xml.publishers do |publishers|
                build_gitlab_publishers(publishers)
              end
              xml.buildWrappers
              build_scm(xml)
            end
          end
          builder.to_xml
        end

        def build_scm(xml)
          if repo_url
            xml.scm(class: 'hudson.plugins.git.GitSCM') do
              xml.userRemoteConfigs do
                xml.send(:"hudson.plugins.git.UserRemoteConfig") do
                  xml.url repo_url
                end
              end
              xml.branches do
                xml.send(:"hudson.plugins.git.BranchSpec") do
                  xml.name
                end
              end
              xml.configVersion 2
              xml.doGenerateSubmoduleConfiguration false
              xml.gitTool 'Default'
            end
          end
        end

        def build_gitlab_connection(xml)
          if gitlab_connection
            xml.send(:"com.dabsquared.gitlabjenkins.connection.GitLabConnectionProperty") do
              xml.gitLabConnection gitlab_connection
            end
          end
        end

        def build_gitlab_triggers(xml)
          if gitlab_connection
            xml.send(:"com.dabsquared.gitlabjenkins.GitLabPushTrigger") do
              xml.spec
              xml.triggerOnPush true
              xml.triggerOnMergeRequest true
              xml.includeBranchesSpec 'main,master'
              xml.branchFilterType 'NameBasedFilter'
              xml.ciSkip true
            end
          end
        end

        def build_gitlab_publishers(xml)
          if gitlab_connection
            xml.send(:"com.dabsquared.gitlabjenkins.publisher.GitLabCommitStatusPublisher") do
              xml.name 'jenkins'
              xml.markUnstableAsSuccess false
            end
          end
        end
      end
    end
  end
end
