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
        project.labels.find_or_create_by!(title: title) do |label|
          label.color = color
        end
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
