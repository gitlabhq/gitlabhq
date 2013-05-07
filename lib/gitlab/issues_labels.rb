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
        labels = important_labels + warning_labels + neutral_labels + positive_labels

        project.issues_default_label_list = labels
        project.save
      end
    end
  end
end
