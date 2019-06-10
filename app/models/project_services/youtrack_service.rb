# frozen_string_literal: true

class YoutrackService < IssueTrackerService
  validates :project_url, :issues_url, presence: true, public_url: true, if: :activated?

  prop_accessor :description, :project_url, :issues_url

  # {PROJECT-KEY}-{NUMBER} Examples: YT-1, PRJ-1, gl-030
  def self.reference_pattern(only_long: false)
    if only_long
      /(?<issue>\b[A-Za-z][A-Za-z0-9_]*-\d+)/
    else
      /(?<issue>\b[A-Za-z][A-Za-z0-9_]*-\d+)|(#{Issue.reference_prefix}(?<issue>\d+))/
    end
  end

  def title
    'YouTrack'
  end

  def description
    if self.properties && self.properties['description'].present?
      self.properties['description']
    else
      'YouTrack issue tracker'
    end
  end

  def self.to_param
    'youtrack'
  end

  def fields
    [
      { type: 'text', name: 'description', placeholder: description },
      { type: 'text', name: 'project_url', placeholder: 'Project url', required: true },
      { type: 'text', name: 'issues_url', placeholder: 'Issue url', required: true }
    ]
  end
end
