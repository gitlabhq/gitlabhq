module Labels
  class GroupService < ::BaseService
    def initialize(project_labels)
      @project_labels = project_labels.group_by(&:title)
    end

    def execute
      build(@project_labels)
    end

    def label(title)
      if title
        group_label = @project_labels[title].group_by(&:title)
        build(group_label).first
      else
        nil
      end
    end

    private

    def build(label)
      label.map { |title, labels| GroupLabel.new(title, labels) }
    end
  end
end
