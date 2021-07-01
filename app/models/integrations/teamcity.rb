# frozen_string_literal: true

module Integrations
  class Teamcity < BaseCi
    include ReactiveService
    include ServicePushDataValidations

    prop_accessor :teamcity_url, :build_type, :username, :password

    validates :teamcity_url, presence: true, public_url: true, if: :activated?
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

    class << self
      def to_param
        'teamcity'
      end

      def supported_events
        %w(push merge_request)
      end

      def event_description(event)
        case event
        when 'push', 'push_events'
          'TeamCity CI will be triggered after every push to the repository except branch delete'
        when 'merge_request', 'merge_request_events'
          'TeamCity CI will be triggered after a merge request has been created or updated'
        end
      end
    end

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
      'JetBrains TeamCity'
    end

    def description
      s_('ProjectService|Run CI/CD pipelines with JetBrains TeamCity.')
    end

    def help
      s_('To run CI/CD pipelines with JetBrains TeamCity, input the GitLab project details in the TeamCity project Version Control Settings.')
    end

    def fields
      [
        {
          type: 'text',
          name: 'teamcity_url',
          title: s_('ProjectService|TeamCity server URL'),
          placeholder: 'https://teamcity.example.com',
          required: true
        },
        {
          type: 'text',
          name: 'build_type',
          help: s_('ProjectService|The build configuration ID of the TeamCity project.'),
          required: true
        },
        {
          type: 'text',
          name: 'username',
          help: s_('ProjectService|Must have permission to trigger a manual build in TeamCity.')
        },
        {
          type: 'password',
          name: 'password',
          non_empty_password_title: s_('ProjectService|Enter new password'),
          non_empty_password_help: s_('ProjectService|Leave blank to use your current password')
        }
      ]
    end

    def build_page(sha, ref)
      with_reactive_cache(sha, ref) {|cached| cached[:build_page] }
    end

    def commit_status(sha, ref)
      with_reactive_cache(sha, ref) {|cached| cached[:commit_status] }
    end

    def calculate_reactive_cache(sha, ref)
      response = get_path("httpAuth/app/rest/builds/branch:unspecified:any,revision:#{sha}")

      if response
        { build_page: read_build_page(response), commit_status: read_commit_status(response) }
      else
        { build_page: teamcity_url, commit_status: :error }
      end
    end

    def execute(data)
      case data[:object_kind]
      when 'push'
        execute_push(data)
      when 'merge_request'
        execute_merge_request(data)
      end
    end

    private

    def execute_push(data)
      branch = Gitlab::Git.ref_name(data[:ref])
      post_to_build_queue(data, branch) if push_valid?(data)
    end

    def execute_merge_request(data)
      branch = data[:object_attributes][:source_branch]
      post_to_build_queue(data, branch) if merge_request_valid?(data)
    end

    def read_build_page(response)
      if response.code != 200
        # If actual build link can't be determined,
        # send user to build summary page.
        build_url("viewLog.html?buildTypeId=#{build_type}")
      else
        # If actual build link is available, go to build result page.
        built_id = response['build']['id']
        build_url("viewLog.html?buildId=#{built_id}&buildTypeId=#{build_type}")
      end
    end

    def read_commit_status(response)
      return :error unless response.code == 200 || response.code == 404

      status = if response.code == 404
                 'Pending'
               else
                 response['build']['status']
               end

      return :error unless status.present?

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

    def build_url(path)
      Gitlab::Utils.append_path(teamcity_url, path)
    end

    def get_path(path)
      Gitlab::HTTP.try_get(build_url(path), verify: false, basic_auth: basic_auth, extra_log_info: { project_id: project_id }, use_read_total_timeout: true)
    end

    def post_to_build_queue(data, branch)
      Gitlab::HTTP.post(
        build_url('httpAuth/app/rest/buildQueue'),
        body: "<build branchName=#{branch.encode(xml: :attr)}>"\
              "<buildType id=#{build_type.encode(xml: :attr)}/>"\
              '</build>',
        headers: { 'Content-type' => 'application/xml' },
        basic_auth: basic_auth,
        use_read_total_timeout: true
      )
    end

    def basic_auth
      { username: username, password: password }
    end
  end
end
