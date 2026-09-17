# frozen_string_literal: true

module Mcp
  module Tools
    module Toolsets
      ALWAYS_ON  = %i[meta].freeze
      DEFAULT    = %i[core merge_requests work_items repository ci].freeze
      OPT_IN     = %i[duo_agent_platform wikis code_security].freeze
      ALL        = (ALWAYS_ON + DEFAULT + OPT_IN).freeze
      UNASSIGNED = :unassigned

      def self.parse(header_value)
        return if header_value.blank?

        names = header_value.split(',').map { |name| name.strip.downcase }.reject(&:blank?)
        return if names.empty?

        valid = ALL.map(&:to_s)
        invalid = names - valid - ['all']
        if invalid.any?
          raise ArgumentError,
            "Unknown toolsets: #{invalid.join(', ')}. Valid toolsets: #{valid.join(', ')}"
        end

        return valid if names.include?('all')

        names
      end

      def self.defaults
        (DEFAULT + ALWAYS_ON).map(&:to_s)
      end
    end
  end
end
