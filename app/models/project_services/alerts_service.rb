# frozen_string_literal: true

# This service is scheduled for removal. All records must
# be deleted before the class can be removed.
# https://gitlab.com/groups/gitlab-org/-/epics/5056
class AlertsService < Service
  before_save :prevent_save

  def self.to_param
    'alerts'
  end

  def self.supported_events
    %w()
  end

  private

  def prevent_save
    errors.add(:base, _('Alerts endpoint is deprecated and should not be created or modified. Use HTTP Integrations instead.'))
    log_error('Prevented attempt to save or update deprecated AlertsService')

    # Stops execution of callbacks and database operation while
    # preserving expectations of #save (will not raise) & #save! (raises)
    # https://guides.rubyonrails.org/active_record_callbacks.html#halting-execution
    throw :abort # rubocop:disable Cop/BanCatchThrow
  end
end
