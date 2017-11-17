module Gitlab
  module LegacyGithubImport
    class LabelFormatter < BaseFormatter
      def attributes
        {
          project: project,
          title: title,
          color: color
        }
      end

      def project_association
        :labels
      end

      def create!
        params  = attributes.except(:project)
        service = ::Labels::FindOrCreateService.new(nil, project, params)
        label   = service.execute(skip_authorization: true)

        raise ActiveRecord::RecordInvalid.new(label) unless label.persisted?

        label
      end

      private

      def color
        "##{raw_data.color}"
      end

      def title
        raw_data.name
      end
    end
  end
end
