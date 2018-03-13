class PivotaltrackerService < Service
  API_ENDPOINT = 'https://www.pivotaltracker.com/services/v5/source_commits'.freeze

  prop_accessor :token, :restrict_to_branch
  validates :token, presence: true, if: :activated?

  def title
    'PivotalTracker'
  end

  def description
    'Project Management Software (Source Commits Endpoint)'
  end

  def self.to_param
    'pivotaltracker'
  end

  def fields
    [
      {
        type: 'text',
        name: 'token',
        placeholder: 'Pivotal Tracker API token.',
        required: true
      },
      {
        type: 'text',
        name: 'restrict_to_branch',
        placeholder: 'Comma-separated list of branches which will be ' \
          'automatically inspected. Leave blank to include all branches.'
      }
    ]
  end

  def self.supported_events
    %w(push)
  end

  def execute(data)
    return unless supported_events.include?(data[:object_kind])
    return unless allowed_branch?(data[:ref])

    data[:commits].each do |commit|
      message = {
        'source_commit' => {
          'commit_id' => commit[:id],
          'author' => commit[:author][:name],
          'url' => commit[:url],
          'message' => commit[:message]
        }
      }
      Gitlab::HTTP.post(
        API_ENDPOINT,
        body: message.to_json,
        headers: {
          'Content-Type' => 'application/json',
          'X-TrackerToken' => token
        }
      )
    end
  end

  private

  def allowed_branch?(ref)
    return true unless ref.present? && restrict_to_branch.present?

    branch = Gitlab::Git.ref_name(ref)
    allowed_branches = restrict_to_branch.split(',').map(&:strip)

    branch.present? && allowed_branches.include?(branch)
  end
end
