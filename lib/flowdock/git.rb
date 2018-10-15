# frozen_string_literal: true
require "multi_json"
require "cgi"
require "flowdock"
require "flowdock/git/builder"

module Flowdock
  class Git
    TokenError = Class.new(StandardError)

    class << self
      def post(ref, from, to, options = {})
        Git.new(ref, from, to, options).post
      end

      def background_post(ref, from, to, options = {})
        Git.new(ref, from, to, options).background_post
      end
    end

    def initialize(ref, from, to, options = {})
      @ref = ref
      @from = from
      @to = to
      @options = options
      @token = options[:token] || config["flowdock.token"] || raise(TokenError.new("Flowdock API token not found"))
      @commit_url = options[:commit_url] || config["flowdock.commit-url-pattern"] || nil
      @diff_url = options[:diff_url] || config["flowdock.diff-url-pattern"] || nil
      @repo_url = options[:repo_url] || config["flowdock.repository-url"] || nil
      @repo_name = options[:repo_name] || config["flowdock.repository-name"] || nil

      refs = options[:permanent_refs] || config["flowdock.permanent-references"] || "refs/heads/master"
      @permanent_refs = refs
        .split(",")
        .map(&:strip)
        .map {|exp| Regexp.new(exp) }
    end

    # Send git push notification to Flowdock
    def post
      messages.each do |message|
        Flowdock::Client.new(flow_token: @token).post_to_thread(message)
      end
    end

    # Create and post notification in background process. Avoid blocking the push notification.
    def background_post
      pid = Process.fork
      if pid.nil?
        Grit::Git.with_timeout(600) do
          post
        end
      else
        Process.detach(pid) # Parent
      end
    end

    def repo
      @repo ||= Grit::Repo.new(
        @options[:repo] || Dir.pwd,
        is_bare: @options[:is_bare] || false
      )
    end

    private

    def messages
      Git::Builder.new(repo: @repo,
                       ref: @ref,
                       before: @from,
                       after: @to,
                       commit_url: @commit_url,
                       branch_url: @branch_url,
                       diff_url: @diff_url,
                       repo_url: @repo_url,
                       repo_name: @repo_name,
                       permanent_refs: @permanent_refs,
                       tags: tags
                      ).to_hashes
    end

    # Flowdock tags attached to the push notification
    def tags
      tags =
        if @options[:tags]
          @options[:tags]
        else
          config["flowdock.tags"].to_s.split(",").map(&:strip)
        end

      tags.map { |t| CGI.escape(t) }
    end

    def config
      @config ||= Grit::Config.new(repo)
    end
  end
end
