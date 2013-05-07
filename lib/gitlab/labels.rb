module Gitlab
  class Labels
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

      def self.generate(project)
        labels = important_labels + warning_labels + neutral_labels + positive_labels

        labels.each do |label_name|
          # create tag for project
        end
      end
    end
  end
end
