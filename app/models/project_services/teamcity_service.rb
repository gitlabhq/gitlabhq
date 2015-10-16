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
#

class TeamcityService < CiService
  include HTTParty

  prop_accessor :teamcity_url, :build_type, :username, :password

  validates :teamcity_url,
    presence: true,
    format: { with: /\A#{URI.regexp}\z/ }, if: :activated?
  validates :build_type, presence: true, if: :activated?
  validates :username,
    presence: true,
    if: ->(service) { service.password? }, if: :activated?
  validates :password,
    presence: true,
    if: ->(service) { service.username? }, if: :activated?

  attr_accessor :response

  after_save :compose_service_hook, if: :activated?
  before_update :reset_password

  def compose_service_hook
    hook = service_hook || build_service_hook
    hook.save
  end

  def reset_password
    if teamcity_url_changed? && !password_touched?
      self.password = nil
    end
  end

  def title
    'JetBrains TeamCity CI'
  end

  def description
    'A continuous integration and build server'
  end

  def help
    'The build configuration in Teamcity must use the build format '\
    'number %build.vcs.number% '\
    'you will also want to configure monitoring of all branches so merge '\
    'requests build, that setting is in the vsc root advanced settings.'
  end

  def to_param
    'teamcity'
  end

  def supported_events
    %w(push)
  end

  def fields
    [
      { type: 'text', name: 'teamcity_url',
        placeholder: 'TeamCity root URL like https://teamcity.example.com' },
      { type: 'text', name: 'build_type',
        placeholder: 'Build configuration ID' },
      { type: 'text', name: 'username',
        placeholder: 'A user with permissions to trigger a manual build' },
      { type: 'password', name: 'password' },
    ]
  end

  def build_info(sha)
    url = URI.parse("#{teamcity_url}/httpAuth/app/rest/builds/"\
                    "branch:unspecified:any,number:#{sha}")
    auth = {
      username: username,
      password: password,
    }
    @response = HTTParty.get("#{url}", verify: false, basic_auth: auth)
  end

  def build_page(sha, ref)
    build_info(sha) if @response.nil? || !@response.code

    if @response.code != 200
      # If actual build link can't be determined,
      # send user to build summary page.
      "#{teamcity_url}/viewLog.html?buildTypeId=#{build_type}"
    else
      # If actual build link is available, go to build result page.
      built_id = @response['build']['id']
      "#{teamcity_url}/viewLog.html?buildId=#{built_id}"\
      "&buildTypeId=#{build_type}"
    end
  end

  def commit_status(sha, ref)
    build_info(sha) if @response.nil? || !@response.code
    return :error unless @response.code == 200 || @response.code == 404

    status = if @response.code == 404
               'Pending'
             else
               @response['build']['status']
             end

    if status.include?('SUCCESS')
      'success'
    elsif status.include?('FAILURE')
      'failed'
    elsif status.include?('Pending')
      'pending'
    else
      :error
    end
  end

  def execute(data)
    return unless supported_events.include?(data[:object_kind])

    auth = {
      username: username,
      password: password,
    }

    branch = Gitlab::Git.ref_name(data[:ref])

    self.class.post("#{teamcity_url}/httpAuth/app/rest/buildQueue",
                    body: "<build branchName=\"#{branch}\">"\
                          "<buildType id=\"#{build_type}\"/>"\
                          '</build>',
                    headers: { 'Content-type' => 'application/xml' },
                    basic_auth: auth
        )
  end
end
