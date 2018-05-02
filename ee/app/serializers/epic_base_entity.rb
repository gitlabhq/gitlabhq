class EpicBaseEntity < Grape::Entity
  include RequestAwareEntity
  include EntityDateHelper

  expose :id
  expose :title
  expose :url do |epic|
    group_epic_path(epic.group, epic)
  end
  expose :human_readable_end_date, if: -> (epic, _) { epic.end_date.present? } do |epic|
    epic.end_date&.to_s(:medium)
  end
  expose :human_readable_timestamp, if: -> (epic, _) { epic.end_date.present? || epic.start_date.present? } do |epic|
    remaining_days_in_words(epic)
  end
end
