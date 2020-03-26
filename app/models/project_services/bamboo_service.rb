# frozen_string_literal: true

class BambooService < CiService
  include ReactiveService

  prop_accessor :bamboo_url, :build_key, :username, :password

  validates :bamboo_url, presence: true, public_url: true, if: :activated?
  validates :build_key, presence: true, if: :activated?
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
    if bamboo_url_changed? && !password_touched?
      self.password = nil
    end
  end

  def title
    s_('BambooService|Atlassian Bamboo CI')
  end

  def description
    s_('BambooService|A continuous integration and build server')
  end

  def help
    s_('BambooService|You must set up automatic revision labeling and a repository trigger in Bamboo.')
  end

  def self.to_param
    'bamboo'
  end

  def fields
    [
        { type: 'text', name: 'bamboo_url',
          placeholder: s_('BambooService|Bamboo root URL like https://bamboo.example.com'), required: true },
        { type: 'text', name: 'build_key',
          placeholder: s_('BambooService|Bamboo build plan key like KEY'), required: true },
        { type: 'text', name: 'username',
          placeholder: s_('BambooService|A user with API access, if applicable') },
        { type: 'password', name: 'password' }
    ]
  end

  def build_page(sha, ref)
    with_reactive_cache(sha, ref) {|cached| cached[:build_page] }
  end

  def commit_status(sha, ref)
    with_reactive_cache(sha, ref) {|cached| cached[:commit_status] }
  end

  def execute(data)
    return unless supported_events.include?(data[:object_kind])

    get_path("updateAndBuild.action", { buildKey: build_key })
  end

  def calculate_reactive_cache(sha, ref)
    response = try_get_path("rest/api/latest/result/byChangeset/#{sha}")

    { build_page: read_build_page(response), commit_status: read_commit_status(response) }
  end

  private

  def get_build_result(response)
    return if response&.code != 200

    # May be nil if no result, a single result hash, or an array if multiple results for a given changeset.
    result = response.dig('results', 'results', 'result')

    # In case of multiple results, arbitrarily assume the last one is the most relevant.
    return result.last if result.is_a?(Array)

    result
  end

  def read_build_page(response)
    result = get_build_result(response)
    key =
      if result.blank?
        # If actual build link can't be determined, send user to build summary page.
        build_key
      else
        # If actual build link is available, go to build result page.
        result.dig('planResultKey', 'key')
      end

    build_url("browse/#{key}")
  end

  def read_commit_status(response)
    return :error unless response && (response.code == 200 || response.code == 404)

    result = get_build_result(response)
    status =
      if result.blank?
        'Pending'
      else
        result.dig('buildState')
      end

    return :error unless status.present?

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

  def try_get_path(path, query_params = {})
    params = build_get_params(query_params)
    params[:extra_log_info] = { project_id: project_id }

    Gitlab::HTTP.try_get(build_url(path), params)
  end

  def get_path(path, query_params = {})
    Gitlab::HTTP.get(build_url(path), build_get_params(query_params))
  end

  def build_url(path)
    Gitlab::Utils.append_path(bamboo_url, path)
  end

  def build_get_params(query_params)
    params = { verify: false, query: query_params }
    return params if username.blank? && password.blank?

    query_params[:os_authType] = 'basic'
    params[:basic_auth] = basic_auth
    params
  end

  def basic_auth
    { username: username, password: password }
  end
end
