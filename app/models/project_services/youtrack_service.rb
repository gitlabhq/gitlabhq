# frozen_string_literal: true

class YoutrackService < IssueTrackerService
  validates :project_url, :issues_url, :new_issue_url, presence: true, public_url: true, if: :activated?

  prop_accessor :title, :description, :project_url, :issues_url, :new_issue_url

  # {PROJECT-KEY}-{NUMBER} Examples: YT-1, PRJ-1
  def self.reference_pattern(only_long: false)
    if only_long
      /(?<issue>\b[A-Z][A-Za-z0-9_]*-\d+)/
    else
      /(?<issue>\b[A-Z][A-Za-z0-9_]*-\d+)|(#{Issue.reference_prefix}(?<issue>\d+))/
    end
  end

  def title
    if self.properties && self.properties['title'].present?
      self.properties['title']
    else
      'YouTrack'
    end
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
end
