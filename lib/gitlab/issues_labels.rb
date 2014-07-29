module Gitlab
  class IssuesLabels
    class << self
      def important_labels
        %w(bug critical confirmed)
      end

      def warning_labels
        %w(documentation support)
      end

      def neutral_labels
        %w(discussion suggestion)
      end

      def positive_labels
        %w(feature enhancement)
      end

      def generate(project)
        label_names = important_labels + warning_labels + neutral_labels + positive_labels

        label_names.each do |label_name|
          project.labels.create(title: label_name)
        end
      end
    end
  end
end
