# frozen_string_literal: true

class AutocompleteTagsService
  def initialize(taggable_type)
    @taggable_type = taggable_type
  end

  # rubocop: disable CodeReuse/ActiveRecord
  def run
    @taggable_type
      .all_tags
      .pluck(:id, :name).map do |id, name|
        { id: id, title: name }
      end
  end
  # rubocop: enable CodeReuse/ActiveRecord
end
