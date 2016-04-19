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
