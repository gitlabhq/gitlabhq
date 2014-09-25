class MigrateTaggableLabels < ActiveRecord::Migration
  def up
    taggings = ActsAsTaggableOn::Tagging.where(taggable_type: ['Issue', 'MergeRequest'], context: 'labels')
    taggings.find_each(batch_size: 500) do |tagging|
      # Clean up orphaned taggings while we are here
      if tagging.taggable.blank? || tagging.tag.nil?
        tagging.destroy
        print 'D'
        next
      end
      create_label_from_tagging(tagging)
    end
  end

  def down
    Label.destroy_all
    LabelLink.destroy_all
  end

  private

  def create_label_from_tagging(tagging)
    target = tagging.taggable
    label_name = tagging.tag.name
    # '?', '&' and ',' are no longer allowed in label names so we remove them
    label_name.tr!('?&,', '')
    label = target.project.labels.find_or_create_by(title: label_name, color: Label::DEFAULT_COLOR)

    if label.valid? && LabelLink.create(label: label, target: target)
      print '.'
    else
      print 'F'
    end
  end
end
