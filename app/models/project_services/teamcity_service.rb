class TeamcityService < CiService
  prop_accessor :teamcity_url, :build_type, :username, :password

  validates :teamcity_url, presence: true, url: true, if: :activated?
  validates :build_type, presence: true, if: :activated?
  validates :username,
    presence: true,
    if: ->(service) { service.activated? && service.password }
  validates :password,
    presence: true,
    if: ->(service) { service.activated? && service.username }

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
    %w[push]
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
    @response = get_path("httpAuth/app/rest/builds/branch:unspecified:any,number:#{sha}")
  end

  def build_page(sha, ref)
    build_info(sha) if @response.nil? || !@response.code

    if @response.code != 200
      # If actual build link can't be determined,
      # send user to build summary page.
      build_url("viewLog.html?buildTypeId=#{build_type}")
    else
      # If actual build link is available, go to build result page.
      built_id = @response['build']['id']
      build_url("viewLog.html?buildId=#{built_id}&buildTypeId=#{build_type}")
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

    HTTParty.post(
      build_url('httpAuth/app/rest/buildQueue'),
      body: "<build branchName=\"#{branch}\">"\
            "<buildType id=\"#{build_type}\"/>"\
            '</build>',
      headers: { 'Content-type' => 'application/xml' },
      basic_auth: auth
    )
  end

  private

  def build_url(path)
    URI.join("#{teamcity_url}/", path).to_s
  end

  def get_path(path)
    HTTParty.get(build_url(path), verify: false,
                                  basic_auth: {
                                    username: username,
                                    password: password
                                  })
  end
end
