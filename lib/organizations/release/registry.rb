# frozen_string_literal: true

module Organizations
  module Release
    # Reads config/organizations_release.yml and turns it into validated
    # Flag objects. This is the single source of truth for which stage each
    # organization flag is at.
    class Registry
      DEFAULT_PATH = 'config/organizations_release.yml'

      class << self
        def instance
          @instance ||= new
        end
      end

      def initialize(path = Rails.root.join(DEFAULT_PATH))
        @path = path
      end

      def flags
        @flags ||= load_flags
      end

      # Returns an organization flag, raising if it is not registered. We raise
      # rather than fail open: an unregistered flag is a programming error, not
      # a rollout state.
      def find(name)
        by_name.fetch(name.to_s) do
          raise UnknownFlagError, "Unknown organization flag: #{name}"
        end
      end

      private

      def by_name
        @by_name ||= flags.index_by(&:name)
      end

      def load_flags
        entries = YAML.safe_load_file(@path).fetch('flags')

        entries.map { |entry| build_flag(entry) }
      end

      def build_flag(entry)
        name = entry.fetch('name')

        Flag.new(
          name: name,
          description: entry.fetch('description'),
          stage: stage_for(name, entry.fetch('stage').to_sym)
        )
      end

      def stage_for(name, stage_key)
        Stage::BY_KEY[stage_key] ||
          raise(UnknownStageError,
            "Organization flag '#{name}' has unknown stage '#{stage_key}'. " \
              "Valid stages: #{Stage::BY_KEY.keys.join(', ')}")
      end
    end
  end
end
