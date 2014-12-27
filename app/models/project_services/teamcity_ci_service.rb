# Base class for CI services
# List methods you need to implement to get your CI service
# working with GitLab Merge Requests

require 'teamcity'

class TeamcityCiService < CiService
  prop_accessor :teamcity_server_url
  prop_accessor :teamcity_build_configuration_id
  prop_accessor :username
  prop_accessor :password

  validates :teamcity_server_url, presence: true, if: :activated?
  validates :teamcity_build_configuration_id, presence: true, if: :activated?
  validates :username, presence: true, if: :activated?
  validates :password, presence: true, if: :activated?

  def build_page(sha)
    build = find_build_id_by_sha sha

    return 'http://error' unless build

    build.webUrl
  rescue => e
    Gitlab::AppLogger.info(
      "Exception: #{e}"
    )

    'http://error'
  end

  def commit_status(sha)
    convert_state_teamcity_to_gitlab(find_build_id_by_sha(sha))
  rescue => e
    Gitlab::AppLogger.info(
      "Exception: #{e}"
    )

    :failed
  end

  def title
    'Teamcity CI'
  end

  def description
    'Continuous integration server from Teamcity'
  end

  def to_param
    'teamcity_ci'
  end

  def fields
    [
      { type: 'text', name: 'teamcity_server_url',
        placeholder: 'https://teamcity.example.com' },
      { type: 'text', name: 'teamcity_build_configuration_id',
        placeholder: 'Build Configuration Id' },
      { type: 'text', name: 'username',
        placeholder: '' },
      { type: 'text', name: 'password',
        placeholder: '' },
    ]
  end

  def execute(_push_data)
  end

  def can_test?
    false
  end

  private

  def find_merge_request_source_branch_by_last_commit(sha)
    project.merge_requests.each do |mr|
      if mr.last_commit.sha == sha
        return mr.source_branch
      end
    end
  end

  def find_build_id_by_sha(sha)
    branch = ERB::Util.url_encode(find_merge_request_source_branch_by_last_commit(sha))
    if branch
      my_find_build_id_by_sha(sha, "refs/heads/#{branch}") ||
        my_find_build_id_by_sha(sha, "#{branch}")
    else
      my_find_build_id_by_sha sha, '(branched:any)'
    end
  end

  def my_find_build_id_by_sha(sha, branch)
    tc = TeamCity.client(
      endpoint: "#{teamcity_server_url}/httpAuth/app/rest",
      http_user: username,
      http_password: password
    )
    builds = tc.builds(
      buildType: teamcity_build_configuration_id,
      branch: branch,
      running: 'any',
      canceled: 'any'
    )

    return nil unless builds

    builds.each do |b|
      info = tc.build(id: b.id)
      info.revisions.revision.each do |r|
        if r.version == sha
          return info
        end
      end
    end

    nil
  end

  STATUS = { 'success' => 'success',
             'failure' => 'failed' }

  def convert_state_teamcity_to_gitlab(build_info)
    return :pending unless build_info
    return :running if build_info.state == 'running'

    if build_info.state.downcase == 'finished'
      if STATUS.has_key?(build_info.status.downcase)
        return STATUS[build_info.status.downcase]
      end
    end

    Gitlab::AppLogger.info(
      "teamcity build_info.state = #{build_info.state}" \
      " with  build_info.status = #{build_info.status} are not supported," \
      ' suppose it failed'
    )

    :failed
  end
end
