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

class AssemblaService < Service
  include HTTParty

  prop_accessor :token, :subdomain
  validates :token, presence: true, if: :activated?

  def title
    'Assembla'
  end

  def description
    'Project Management Software (Source Commits Endpoint)'
  end

  def to_param
    'assembla'
  end

  def fields
    [
      { type: 'text', name: 'token', placeholder: '' },
      { type: 'text', name: 'subdomain', placeholder: '' }
    ]
  end

  def supported_events
    %w(push)
  end

  def execute(data)
    return unless supported_events.include?(data[:object_kind])

    url = "https://atlas.assembla.com/spaces/#{subdomain}/github_tool?secret_key=#{token}"
    AssemblaService.post(url, body: { payload: data }.to_json, headers: { 'Content-Type' => 'application/json' })
  end
end
