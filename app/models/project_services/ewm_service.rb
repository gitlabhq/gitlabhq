# frozen_string_literal: true

class EwmService < IssueTrackerService
  validates :project_url, :issues_url, :new_issue_url, presence: true, public_url: true, if: :activated?

  def self.reference_pattern(only_long: true)
    @reference_pattern ||= %r{(?<issue>\b(bug|task|work item|workitem|rtcwi|defect)\b\s+\d+)}i
  end

  def title
    'EWM'
  end

  def description
    s_('IssueTracker|EWM work items tracker')
  end

  def self.to_param
    'ewm'
  end

  def can_test?
    false
  end

  def issue_url(iid)
    issues_url.gsub(':id', iid.to_s.split(' ')[-1])
  end
end
