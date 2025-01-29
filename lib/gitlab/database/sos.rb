# frozen_string_literal: true

# WIP
module Gitlab
  module Database
    module Sos
      TASKS = [
        Sos::ShowAllSettings,
        Sos::PgConstraints
      ].freeze

      def self.run(output_file)
        Output.writing(output_file, mode: :directory) do |output|
          TASKS.each { |t| t.run(output) }
        end
      end
    end
  end
end
