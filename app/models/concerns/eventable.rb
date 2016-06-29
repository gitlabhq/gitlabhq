module Eventable
  extend ActiveSupport::Concern

  def events
    Event.where(target_id: id, target_type: self.class.to_s)
  end

  def events=(events)
    events.each do |event|
      event.target_id = id
      event.data.deep_symbolize_keys! if event.data
      event.save!
    end
  end
end