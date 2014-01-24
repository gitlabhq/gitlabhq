# == Schema Information
#
# Table name: services
#
#  id          :integer          not null, primary key
#  type        :string(255)
#  title       :string(255)
#  token       :string(255)
#  project_id  :integer          not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  active      :boolean          default(FALSE), not null
#  project_url :string(255)
#  subdomain   :string(255)
#  room        :string(255)
#

class AssemblaService < Service
  attr_accessible :subdomain

  include HTTParty

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

  def execute(push)
    url = "https://atlas.assembla.com/spaces/#{subdomain}/github_tool?secret_key=#{token}"
    AssemblaService.post(url, body: { payload: push }.to_json, headers: { 'Content-Type' => 'application/json' })
  end
end
