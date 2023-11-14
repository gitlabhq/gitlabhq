# frozen_string_literal: true

module Issuable
  module ImportCsv
    class BaseService < ::ImportCsv::BaseService
      extend ::Gitlab::Utils::Override

      private

      override :attributes_for
      def attributes_for(row)
        {
          title: row[:title],
          description: row[:description],
          due_date: row[:due_date],
          milestone_id: find_milestone_by_title(row[:milestone])
        }
      end

      override :validate_headers_presence!
      def validate_headers_presence!(headers)
        headers.downcase! if headers
        return if headers && headers.include?('title') && headers.include?('description')

        raise CSV::MalformedCSVError.new('Invalid CSV format - missing required headers.', 1)
      end

      def preprocess!
        preprocess_milestones!

        raise PreprocessError if results[:preprocess_errors].any?
      end

      def preprocess_milestones!
        # Pre-Process Milestone if header is present
        return unless csv_data.lines.first.downcase.include?('milestone')

        provided_titles = with_csv_lines.filter_map { |row| row[:milestone]&.strip }.uniq
        result = ::ImportCsv::PreprocessMilestonesService.new(user, project, provided_titles).execute
        @available_milestones = result.payload
        return if result.success?

        # collate errors here and throw errors
        results[:preprocess_errors][:milestone_errors] = result.payload
      end

      def find_milestone_by_title(title)
        return unless title

        @available_milestones.find { |milestone| milestone.title == title.to_s.strip } if @available_milestones
      end
    end
  end
end
