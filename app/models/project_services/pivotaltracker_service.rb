class PivotaltrackerService < Service
  include HTTParty

  prop_accessor :token
  validates :token, presence: true, if: :activated?

  def title
    'PivotalTracker'
  end

  def description
    'Project Management Software (Source Commits Endpoint)'
  end

  def to_param
    'pivotaltracker'
  end

  def fields
    [
      { type: 'text', name: 'token', placeholder: '' }
    ]
  end

  def supported_events
    %w(push)
  end

  def execute(data)
    return unless supported_events.include?(data[:object_kind])

    url = 'https://www.pivotaltracker.com/services/v5/source_commits'
    data[:commits].each do |commit|
      message = {
        'source_commit' => {
          'commit_id' => commit[:id],
          'author' => commit[:author][:name],
          'url' => commit[:url],
          'message' => commit[:message]
        }
      }
      PivotaltrackerService.post(
        url,
        body: message.to_json,
        headers: {
          'Content-Type' => 'application/json',
          'X-TrackerToken' => token
        }
      )
    end
  end
end
