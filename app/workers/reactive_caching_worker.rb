# frozen_string_literal: true

class ReactiveCachingWorker
  include ApplicationWorker

  # rubocop: disable CodeReuse/ActiveRecord
  def perform(class_name, id, *args)
    klass = begin
      class_name.constantize
    rescue NameError
      nil
    end
    return unless klass

    klass.find_by(klass.primary_key => id).try(:exclusively_update_reactive_cache!, *args)
  end
  # rubocop: enable CodeReuse/ActiveRecord
end
