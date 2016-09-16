module Labels
  class UpdateService < Labels::BaseService
    def execute(label)
      previous_title = label.title.dup

      Label.transaction do
        label.update(params)

        return label unless label.valid?

        replicate_global_label(label.label_type, previous_title, &update_all) if label.global_label?
        replicate_group_label(label.label_type, previous_title, &update_all) if label.group_label?

        label
      end
    end

    private

    def update_all
      Proc.new { |labels| labels.update_all(params) }
    end
  end
end
