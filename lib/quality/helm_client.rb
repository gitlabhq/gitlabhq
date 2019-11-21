# frozen_string_literal: true

require 'time'
require_relative '../gitlab/popen' unless defined?(Gitlab::Popen)

module Quality
  class HelmClient
    CommandFailedError = Class.new(StandardError)

    attr_reader :tiller_namespace, :namespace

    RELEASE_JSON_ATTRIBUTES = %w[Name Revision Updated Status Chart AppVersion Namespace].freeze

    Release = Struct.new(:name, :revision, :last_update, :status, :chart, :app_version, :namespace) do
      def revision
        @revision ||= self[:revision].to_i
      end

      def last_update
        @last_update ||= Time.parse(self[:last_update])
      end
    end

    # A single page of data and the corresponding page number.
    Page = Struct.new(:releases, :number)

    def initialize(tiller_namespace:, namespace:)
      @tiller_namespace = tiller_namespace
      @namespace = namespace
    end

    def releases(args: [])
      each_release(args)
    end

    def delete(release_name:)
      run_command([
        'delete',
        %(--tiller-namespace "#{tiller_namespace}"),
        '--purge',
        release_name
      ])
    end

    private

    def run_command(command)
      final_command = ['helm', *command].join(' ')
      puts "Running command: `#{final_command}`" # rubocop:disable Rails/Output

      result = Gitlab::Popen.popen_with_detail([final_command])

      if result.status.success?
        result.stdout.chomp.freeze
      else
        raise CommandFailedError, "The `#{final_command}` command failed (status: #{result.status}) with the following error:\n#{result.stderr}"
      end
    end

    def raw_releases(args = [])
      command = [
        'list',
        %(--namespace "#{namespace}"),
        %(--tiller-namespace "#{tiller_namespace}" --output json),
        *args
      ]
      json = JSON.parse(run_command(command))

      releases = json['Releases'].map do |json_release|
        Release.new(*json_release.values_at(*RELEASE_JSON_ATTRIBUTES))
      end

      [releases, json['Next']]
    rescue JSON::ParserError => ex
      puts "Ignoring this JSON parsing error: #{ex}" # rubocop:disable Rails/Output
      [[], nil]
    end

    # Fetches data from Helm and yields a Page object for every page
    # of data, without loading all of them into memory.
    #
    # method - The Octokit method to use for getting the data.
    # args - Arguments to pass to the `helm list` command.
    def each_releases_page(args, &block)
      return to_enum(__method__, args) unless block_given?

      page = 1
      offset = ''

      loop do
        final_args = args.dup
        final_args << "--offset #{offset}" unless offset.to_s.empty?
        collection, offset = raw_releases(final_args)

        yield Page.new(collection, page += 1)

        break if offset.to_s.empty?
      end
    end

    # Iterates over all of the releases.
    #
    # args - Any arguments to pass to the `helm list` command.
    def each_release(args, &block)
      return to_enum(__method__, args) unless block_given?

      each_releases_page(args) do |page|
        page.releases.each do |release|
          yield release
        end
      end
    end
  end
end
