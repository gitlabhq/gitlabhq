# == Schema Information
#
# Table name: services
#
#  id          :integer          not null, primary key
#  type        :string(255)
#  title       :string(255)
#  project_id  :integer          not null
#  created_at  :datetime
#  updated_at  :datetime
#  active      :boolean          default(FALSE), not null
#  properties  :text
#

class JenkinsService < CiService
  prop_accessor :project_url

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
      # img.build-caption-status-icon for old jenkins version
      src = Nokogiri.parse(response).css('img.build-caption-status-icon,.build-caption>img').first.attributes['src'].value
      if src =~ /blue\.png$/
        'success'
      elsif src =~ /(red\.png|aborted\.png)$/
        'failed'
      elsif src =~ /anime\.gif$/
        'running'
      else
        'pending'
      end
    else
      :error
    end
  end
end
