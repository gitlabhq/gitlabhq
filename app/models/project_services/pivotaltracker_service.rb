# == Schema Information
#
# Table name: services
#
#  id                    :integer          not null, primary key
#  type                  :string(255)
#  title                 :string(255)
#  project_id            :integer
#  created_at            :datetime
#  updated_at            :datetime
#  active                :boolean          default(FALSE), not null
#  properties            :text
#  template              :boolean          default(FALSE)
#  push_events           :boolean          default(TRUE)
#  issues_events         :boolean          default(TRUE)
#  merge_requests_events :boolean          default(TRUE)
#  tag_push_events       :boolean          default(TRUE)
#  note_events           :boolean          default(TRUE), not null
#  build_events          :boolean          default(FALSE), not null
#

class PivotaltrackerService < Service
  API_ENDPOINT = 'https://www.pivotaltracker.com/services/v5/source_commits'

  prop_accessor :token, :restrict_to_branch
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
      {
        type: 'text',
        name: 'token',
        placeholder: 'Pivotal Tracker API token.'
      },
      {
        type: 'text',
        name: 'restrict_to_branch',
        placeholder: 'Comma-separated list of branches which will be ' \
          'automatically inspected. Leave blank to include all branches.'
      }
    ]
  end

  def supported_events
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
      HTTParty.post(
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
