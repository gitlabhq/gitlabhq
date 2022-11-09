# rubocop: disable Naming/FileName
# frozen_string_literal: true

module QA
  module Support
    class FIPS
      def self.enabled?
        %w[1 true yes].include?(ENV['FIPS'].to_s)
      end
    end
  end
end

# rubocop: enable Naming/FileName
