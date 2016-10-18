module Gitlab
  module GithubImport
    class LabelFormatter < BaseFormatter
      def attributes
        {
          project: project,
          title: title,
          color: color
        }
      end

      def klass
        Label
      end

      def create!
        params  = attributes.except(:project)
        service = ::Labels::CreateService.new(project.owner, project, params)

        service.execute
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
