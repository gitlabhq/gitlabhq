# frozen_string_literal: true

module Integrations
  module HasDataFields
    extend ActiveSupport::Concern

    class_methods do
      # Provide convenient accessor methods for data fields.
      # TODO: Simplify as part of https://gitlab.com/gitlab-org/gitlab/issues/29404
      def data_field(*args)
        args.each do |arg|
          self.class_eval <<-RUBY, __FILE__, __LINE__ + 1
            unless method_defined?(arg)
              def #{arg}
                value = data_fields.send('#{arg}')
                value.nil? ? properties&.dig('#{arg}') : value
              end
            end

            def #{arg}=(value)
              @old_data_fields ||= {}
              @old_data_fields['#{arg}'] ||= #{arg} # set only on the first assignment, IOW we remember the original value only
              data_fields.send('#{arg}=', value)
            end

            def #{arg}_touched?
              @old_data_fields ||= {}
              @old_data_fields.has_key?('#{arg}')
            end

            def #{arg}_changed?
              #{arg}_touched? && @old_data_fields['#{arg}'] != #{arg}
            end

            def #{arg}_was
              return unless #{arg}_touched?
              return if data_fields.persisted? # arg_was does not work for attr_encrypted

              legacy_properties_data['#{arg}']
            end
          RUBY
        end
      end
    end

    included do
      has_one :issue_tracker_data, autosave: true, inverse_of: :integration, foreign_key: :integration_id, class_name: 'Integrations::IssueTrackerData'
      has_one :jira_tracker_data, autosave: true, inverse_of: :integration, foreign_key: :integration_id, class_name: 'Integrations::JiraTrackerData'
      has_one :zentao_tracker_data, autosave: true, inverse_of: :integration, foreign_key: :integration_id, class_name: 'Integrations::ZentaoTrackerData'

      def data_fields
        raise NotImplementedError
      end

      def data_fields_present?
        data_fields.present?
      rescue NotImplementedError
        false
      end
    end
  end
end
