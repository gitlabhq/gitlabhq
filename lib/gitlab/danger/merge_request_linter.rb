# frozen_string_literal: true

base_linter_path = File.expand_path('base_linter', __dir__)

if defined?(Rails)
  require_dependency(base_linter_path)
else
  require_relative(base_linter_path)
end

module Gitlab
  module Danger
    class MergeRequestLinter < BaseLinter
      alias_method :lint, :lint_subject

      def self.subject_description
        'merge request title'
      end

      def self.mr_run_options_regex
        [
          'RUN AS-IF-FOSS',
          'UPDATE CACHE',
          'RUN ALL RSPEC',
          'SKIP RSPEC FAIL-FAST'
        ].join('|')
      end

      private

      def subject
        super.gsub(/\[?(#{self.class.mr_run_options_regex})\]?/, '').strip
      end
    end
  end
end
