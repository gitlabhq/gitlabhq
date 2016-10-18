# Labels::TransferService class
#
# User for recreate the missing group labels at project level
#
module Labels
  class TransferService
    def initialize(current_user, group, project)
      @current_user = current_user
      @group = group
      @project = project
    end

    def execute
      return unless group.present?

      Label.transaction do
        labels_to_transfer = Label.where(id: label_links.select(:label_id))

        labels_to_transfer.find_each do |label|
          new_label_id = find_or_create_label!(label)

          next if new_label_id == label.id

          LabelLink.where(label_id: label.id).update_all(label_id: new_label_id)
          LabelPriority.where(project_id: project.id, label_id: label.id).update_all(label_id: new_label_id)
        end
      end
    end

    private

    attr_reader :current_user, :group, :project

    def label_links
      label_link_ids = []
      label_link_ids << LabelLink.where(target: project.issues, label: group.labels).select(:id)
      label_link_ids << LabelLink.where(target: project.merge_requests, label: group.labels).select(:id)

      union = Gitlab::SQL::Union.new(label_link_ids)

      LabelLink.where("label_links.id IN (#{union.to_sql})")
    end

    def labels
      @labels ||= LabelsFinder.new(current_user, project_id: project.id).execute
    end

    def find_or_create_label!(label)
      new_label = labels.find_by(title: label.title)
      new_label ||= project.labels.create!(label.attributes.slice("title", "description", "color"))

      new_label.id
    end
  end
end
