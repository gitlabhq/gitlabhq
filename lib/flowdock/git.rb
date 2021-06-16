# frozen_string_literal: true
require 'flowdock'
require 'flowdock/git/builder'

module Flowdock
  class Git
    TokenError = Class.new(StandardError)

    DEFAULT_PERMANENT_REFS = [
      Regexp.new('refs/heads/master')
    ].freeze

    class << self
      def post(ref, from, to, options = {})
        Git.new(ref, from, to, options).post
      end
    end

    def initialize(ref, from, to, options = {})
      raise TokenError, "Flowdock API token not found" unless options[:token]

      @ref = ref
      @from = from
      @to = to
      @options = options
      @token = options[:token]
      @commit_url = options[:commit_url]
      @diff_url = options[:diff_url]
      @repo_url = options[:repo_url]
      @repo_name = options[:repo_name]
      @permanent_refs = options.fetch(:permanent_refs, DEFAULT_PERMANENT_REFS)
    end

    # Send git push notification to Flowdock
    def post
      messages.each do |message|
        ::Flowdock::Client.new(flow_token: @token).post_to_thread(message)
      end
    end

    def repo
      @options[:repo]
    end

    private

    def messages
      Git::Builder.new(repo: repo,
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
      Array(@options[:tags]).map { |tag| CGI.escape(tag) }
    end
  end
end
