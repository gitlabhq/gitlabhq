# frozen_string_literal: true

module Integrations
  class DroneCi < BaseCi
    include ReactiveService
    include ServicePushDataValidations

    prop_accessor :drone_url, :token
    boolean_accessor :enable_ssl_verification

    validates :drone_url, presence: true, public_url: true, if: :activated?
    validates :token, presence: true, if: :activated?

    after_save :compose_service_hook, if: :activated?

    def compose_service_hook
      hook = service_hook || build_service_hook
      # If using a service template, project may not be available
      hook.url = [drone_url, "/hook", "?owner=#{project.namespace.full_path}", "&name=#{project.path}", "&access_token=#{token}"].join if project
      hook.enable_ssl_verification = !!enable_ssl_verification
      hook.save
    end

    def execute(data)
      case data[:object_kind]
      when 'push'
        service_hook.execute(data) if push_valid?(data)
      when 'merge_request'
        service_hook.execute(data) if merge_request_valid?(data)
      when 'tag_push'
        service_hook.execute(data) if tag_push_valid?(data)
      end
    end

    def allow_target_ci?
      true
    end

    def self.supported_events
      %w(push merge_request tag_push)
    end

    def commit_status_path(sha, ref)
      Gitlab::Utils.append_path(
        drone_url,
        "gitlab/#{project.full_path}/commits/#{sha}?branch=#{Addressable::URI.encode_component(ref.to_s)}&access_token=#{token}")
    end

    def commit_status(sha, ref)
      with_reactive_cache(sha, ref) { |cached| cached[:commit_status] }
    end

    def calculate_reactive_cache(sha, ref)
      response = Gitlab::HTTP.try_get(
        commit_status_path(sha, ref),
        verify: enable_ssl_verification,
        extra_log_info: { project_id: project_id },
        use_read_total_timeout: true
      )

      status =
        if response && response.code == 200 && response['status']
          case response['status']
          when 'killed'
            :canceled
          when 'failure', 'error'
            # Because drone return error if some test env failed
            :failed
          else
            response["status"]
          end
        else
          :error
        end

      { commit_status: status }
    end

    def build_page(sha, ref)
      Gitlab::Utils.append_path(
        drone_url,
        "gitlab/#{project.full_path}/redirect/commits/#{sha}?branch=#{Addressable::URI.encode_component(ref.to_s)}")
    end

    def title
      'Drone'
    end

    def description
      s_('ProjectService|Run CI/CD pipelines with Drone.')
    end

    def self.to_param
      'drone_ci'
    end

    def help
      s_('ProjectService|Run CI/CD pipelines with Drone.')
    end

    def fields
      [
        { type: 'text', name: 'token', help: s_('ProjectService|Token for the Drone project.'), required: true },
        { type: 'text', name: 'drone_url', title: s_('ProjectService|Drone server URL'), placeholder: 'http://drone.example.com', required: true },
        { type: 'checkbox', name: 'enable_ssl_verification', title: "Enable SSL verification" }
      ]
    end
  end
end
