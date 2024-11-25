# frozen_string_literal: true

module Integrations
  class Jenkins < Integration
    include Base::Ci
    include HasWebHook

    prepend EnableSslVerification

    field :jenkins_url,
      title: -> { s_('ProjectService|Jenkins server URL') },
      exposes_secrets: true,
      required: true,
      placeholder: 'http://jenkins.example.com',
      help: -> { s_('URL of the Jenkins server.') }

    field :project_name,
      required: true,
      placeholder: 'my_project_name',
      help: -> { s_('Name of the Jenkins project.') }

    field :username,
      help: -> { s_('Username of the Jenkins server.') }

    field :password,
      type: :password,
      help: -> { s_('Password of the Jenkins server.') },
      non_empty_password_title: -> { s_('ProjectService|Enter new password.') },
      non_empty_password_help: -> { s_('ProjectService|Leave blank to use your current password.') }

    validates :jenkins_url, presence: true, addressable_url: true, if: :activated?
    validates :project_name, presence: true, if: :activated?
    validates :username, presence: true, if: ->(service) { service.activated? && service.password_touched? && service.password.present? }
    validates :password, presence: true, if: ->(service) { service.activated? && service.username.present? }

    attribute :merge_requests_events, default: false
    attribute :tag_push_events, default: false

    def execute(data)
      return unless supported_events.include?(data[:object_kind])

      execute_web_hook!(data, "#{data[:object_kind]}_hook")
    end

    def test(data)
      begin
        result = execute(data)
        return { success: false, result: result.message } if result.payload[:http_status] != 200
      rescue StandardError => e
        return { success: false, result: e }
      end

      { success: true, result: result.message }
    end

    override :hook_url
    def hook_url
      url = URI.parse(jenkins_url)
      url.path = File.join(url.path || '/', "project/#{project_name}")
      url.user = ERB::Util.url_encode(username) unless username.blank?
      url.password = ERB::Util.url_encode(password) unless password.blank?
      url.to_s
    end

    def url_variables
      {}
    end

    def self.supported_events
      %w[push merge_request tag_push]
    end

    def self.title
      'Jenkins'
    end

    def self.description
      s_('Run CI/CD pipelines with Jenkins.')
    end

    def self.help
      build_help_page_url(
        'integration/jenkins.md',
        s_("Run CI/CD pipelines with Jenkins when you push to a repository, or when a merge request is created, updated, or merged.")
      )
    end

    def self.to_param
      'jenkins'
    end
  end
end
