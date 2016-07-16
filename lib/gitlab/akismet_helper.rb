module Gitlab
  module AkismetHelper
    def akismet_enabled?
      current_application_settings.akismet_enabled
    end

    def akismet_client
      @akismet_client ||= ::Akismet::Client.new(current_application_settings.akismet_api_key,
        Gitlab.config.gitlab.url)
    end

    def client_ip(env)
      env['action_dispatch.remote_ip'].to_s
    end

    def user_agent(env)
      env['HTTP_USER_AGENT']
    end

    def check_for_spam?(project, user)
      akismet_enabled? && !project.team.member?(user)
    end

    def is_spam?(environment, user, text)
      client = akismet_client
      ip_address = client_ip(environment)
      user_agent = user_agent(environment)

      params = {
        type: 'comment',
        text: text,
        created_at: DateTime.now,
        author: user.name,
        author_email: user.email,
        referrer: environment['HTTP_REFERER'],
      }

      begin
        is_spam, is_blatant = client.check(ip_address, user_agent, params)
        is_spam || is_blatant
      rescue => e
        Rails.logger.error("Unable to connect to Akismet: #{e}, skipping check")
        false
      end
    end

    def create_spam_log(project, current_user, attrs, env, api: true)
      params = attrs.merge({
                             source_ip: client_ip(env),
                             user_agent: user_agent(env),
                             noteable_type: 'Issue',
                             via_api: api
                           })

      ::CreateSpamLogService.new(project, current_user, params).execute
    end
  end
end
