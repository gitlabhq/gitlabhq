# == Schema Information
#
# Table name: services
#
#  id          :integer          not null, primary key
#  type        :string(255)
#  title       :string(255)
#  token       :string(255)
#  project_id  :integer          not null
#  created_at  :datetime
#  updated_at  :datetime
#  active      :boolean          default(FALSE), not null
#  project_url :string(255)
#  subdomain   :string(255)
#  room        :string(255)
#  recipients  :text
#  api_key     :string(255)
#

class JenkinsService < CiService
  validates :project_url, presence: true, if: :activated?

  delegate :execute, to: :service_hook, prefix: nil

  after_save :compose_service_hook, if: :activated?

  def compose_service_hook
    hook = service_hook || build_service_hook
    jenkins_url = project_url.sub(/job\/.*/, '')
    hook.url = jenkins_url + "/gitlab/build_now"
    hook.save
  end

  def title
    'Jenkins CI'
  end

  def description
    'An extendable open source continuous integration server'
  end

  def help
    'You must have installed GitLab Hook plugin into Jenkins.'
  end

  def to_param
    'jenkins'
  end

  def fields
    [
      { type: 'text', name: 'project_url', placeholder: 'Jenkins project URL like http://jenkins.example.com/job/my-project/' }
    ]
  end

  def build_page sha
    project_url + "/scm/bySHA1/#{sha}"
  end

  def commit_status sha
    parsed_url = URI.parse(build_page(sha))

    if parsed_url.userinfo.blank?
      response = HTTParty.get(build_page(sha), verify: false)
    else
      get_url = build_page(sha).gsub("#{parsed_url.userinfo}@", "")
      auth = {
          username: URI.decode(parsed_url.user),
          password: URI.decode(parsed_url.password),
      }
      response = HTTParty.get(get_url, verify: false, basic_auth: auth)
    end

    if response.code == 200
      status = Nokogiri.parse(response).xpath('//img[@class="build-caption-status-icon"]').first.attributes['alt'].value
      if status.include?('Success')
        'success'
      elsif status.include?('Failed') || status.include?('Aborted')
        'failed'
      elsif status.include?('In progress')
        'running'
      else
        'pending'
      end
    else
      :error
    end
  end
end
