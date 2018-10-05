# frozen_string_literal: true

require 'time'
require_relative '../gitlab/popen' unless defined?(Gitlab::Popen)

module Quality
  class HelmClient
    attr_reader :namespace

    Release = Struct.new(:name, :revision, :last_update, :status, :chart, :namespace) do
      def revision
        @revision ||= self[:revision].to_i
      end

      def last_update
        @last_update ||= Time.parse(self[:last_update])
      end
    end

    def initialize(namespace: ENV['KUBE_NAMESPACE'])
      @namespace = namespace
    end

    def releases(args: [])
      command = ['list', %(--namespace "#{namespace}"), *args]

      run_command(command)
        .stdout
        .lines
        .select { |line| line.include?(namespace) }
        .map { |line| Release.new(*line.split(/\t/).map(&:strip)) }
    end

    def delete(release_name:)
      run_command(['delete', '--purge', release_name])
    end

    private

    def run_command(command)
      final_command = ['helm', *command].join(' ')
      puts "Running command: `#{final_command}`" # rubocop:disable Rails/Output

      Gitlab::Popen.popen_with_detail([final_command])
    end
  end
end
