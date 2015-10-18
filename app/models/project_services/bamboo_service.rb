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

class BambooService < CiService
  include HTTParty

  prop_accessor :bamboo_url, :build_key, :username, :password

  validates :bamboo_url,
    presence: true,
    format: { with: /\A#{URI.regexp}\z/ },
    if: :activated?
  validates :build_key, presence: true, if: :activated?
  validates :username,
    presence: true,
    if: ->(service) { service.password? },
    if: :activated?
  validates :password,
    presence: true,
    if: ->(service) { service.username? },
    if: :activated?

  attr_accessor :response

  after_save :compose_service_hook, if: :activated?
  before_update :reset_password

  def compose_service_hook
    hook = service_hook || build_service_hook
    hook.save
  end

  def reset_password
    if bamboo_url_changed? && !password_touched?
      self.password = nil
    end
  end

  def title
    'Atlassian Bamboo CI'
  end

  def description
    'A continuous integration and build server'
  end

  def help
    'You must set up automatic revision labeling and a repository trigger in Bamboo.'
  end

  def to_param
    'bamboo'
  end

  def fields
    [
        { type: 'text', name: 'bamboo_url',
          placeholder: 'Bamboo root URL like https://bamboo.example.com' },
        { type: 'text', name: 'build_key',
          placeholder: 'Bamboo build plan key like KEY' },
        { type: 'text', name: 'username',
          placeholder: 'A user with API access, if applicable' },
        { type: 'password', name: 'password' },
    ]
  end

  def supported_events
    %w(push)
  end
  
  def build_info(sha)
    url = URI.parse("#{bamboo_url}/rest/api/latest/result?label=#{sha}")

    if username.blank? && password.blank?
      @response = HTTParty.get(parsed_url.to_s, verify: false)
    else
      get_url = "#{url}&os_authType=basic"
      auth = {
          username: username,
          password: password,
      }
      @response = HTTParty.get(get_url, verify: false, basic_auth: auth)
    end
  end

  def build_page(sha, ref)
    build_info(sha) if @response.nil? || !@response.code

    if @response.code != 200 || @response['results']['results']['size'] == '0'
      # If actual build link can't be determined, send user to build summary page.
      "#{bamboo_url}/browse/#{build_key}"
    else
      # If actual build link is available, go to build result page.
      result_key = @response['results']['results']['result']['planResultKey']['key']
      "#{bamboo_url}/browse/#{result_key}"
    end
  end

  def commit_status(sha, ref)
    build_info(sha) if @response.nil? || !@response.code
    return :error unless @response.code == 200 || @response.code == 404

    status = if @response.code == 404 || @response['results']['results']['size'] == '0'
               'Pending'
             else
               @response['results']['results']['result']['buildState']
             end

    if status.include?('Success')
      'success'
    elsif status.include?('Failed')
      'failed'
    elsif status.include?('Pending')
      'pending'
    else
      :error
    end
  end

  def execute(data)
    return unless supported_events.include?(data[:object_kind])

    # Bamboo requires a GET and does not take any data.
    self.class.get("#{bamboo_url}/updateAndBuild.action?buildKey=#{build_key}",
                   verify: false)
  end
end
