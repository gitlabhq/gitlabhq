module Labels
  class DestroyService < Labels::BaseService
    def execute(label)
      Label.transaction do
        label.destroy

        return if label.project_label?

        replicate_global_label(label.label_type, label.title, &destroy) if label.global_label?
        replicate_group_label(label.label_type, label.title, &destroy) if label.group_label?
      end
    end

    private

    def destroy
      Proc.new { |labels| labels.each(&:destroy) }
    end
  end
end
