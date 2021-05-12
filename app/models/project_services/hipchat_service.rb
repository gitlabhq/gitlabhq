# frozen_string_literal: true

# This service is scheduled for removal. All records must
# be deleted before the class can be removed.
# https://gitlab.com/gitlab-org/gitlab/-/issues/27954
class HipchatService < Integration
  before_save :prevent_save

  def self.to_param
    'hipchat'
  end

  def self.supported_events
    []
  end

  def execute(data)
    # We removed the hipchat gem due to https://gitlab.com/gitlab-org/gitlab/-/issues/325851#note_537143149
    # HipChat is unusable anyway, so do nothing in this method
  end

  private

  def prevent_save
    errors.add(:base, _('HipChat endpoint is deprecated and should not be created or modified.'))

    # Stops execution of callbacks and database operation while
    # preserving expectations of #save (will not raise) & #save! (raises)
    # https://guides.rubyonrails.org/active_record_callbacks.html#halting-execution
    throw :abort # rubocop:disable Cop/BanCatchThrow
  end
end
