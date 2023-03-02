# frozen_string_literal: true

module Integrations
  class Campfire < Integration
    SUBDOMAIN_REGEXP = %r{\A[a-z](?:[a-z0-9-]*[a-z0-9])?\z}i.freeze

    validates :token, presence: true, if: :activated?
    validates :room,
      allow_blank: true,
      numericality: { only_integer: true, greater_than: 0 }
    validates :subdomain,
      allow_blank: true,
      format: { with: SUBDOMAIN_REGEXP }, length: { in: 1..63 }

    field :token,
      type: 'password',
      title: -> { _('Campfire token') },
      help: -> { s_('CampfireService|API authentication token from Campfire.') },
      non_empty_password_title: -> { s_('ProjectService|Enter new token') },
      non_empty_password_help: -> { s_('ProjectService|Leave blank to use your current token.') },
      placeholder: '',
      required: true

    field :subdomain,
      title: -> { _('Campfire subdomain (optional)') },
      placeholder: '',
      exposes_secrets: true,
      help: -> do
        ERB::Util.html_escape(
          s_('CampfireService|The %{code_open}.campfirenow.com%{code_close} subdomain.')
        ) % {
          code_open: '<code>'.html_safe,
          code_close: '</code>'.html_safe
        }
      end

    field :room,
      title: -> { _('Campfire room ID (optional)') },
      placeholder: '123456',
      help: -> { s_('CampfireService|From the end of the room URL.') }

    def title
      'Campfire'
    end

    def description
      'Send notifications about push events to Campfire chat rooms.'
    end

    def help
      docs_link = ActionController::Base.helpers.link_to _('Learn more.'), Rails.application.routes.url_helpers.help_page_url('api/services', anchor: 'campfire'), target: '_blank', rel: 'noopener noreferrer'

      ERB::Util.html_escape(
        s_('CampfireService|Send notifications about push events to Campfire chat rooms. %{docs_link}')
      ) % {
        docs_link: docs_link.html_safe
      }
    end

    def self.to_param
      'campfire'
    end

    def self.supported_events
      %w(push)
    end

    def execute(data)
      return unless supported_events.include?(data[:object_kind])

      message = create_message(data)
      speak(self.room, message, auth)
    end

    private

    def base_uri
      @base_uri ||= "https://#{subdomain}.campfirenow.com"
    end

    def auth
      # use a dummy password, as explained in the Campfire API doc:
      # https://github.com/basecamp/campfire-api#authentication
      @auth ||= {
        basic_auth: {
          username: token,
          password: 'X'
        }
      }
    end

    # Post a message into a room, returns the message Hash in case of success.
    # Returns nil otherwise.
    # https://github.com/basecamp/campfire-api/blob/master/sections/messages.md#create-message
    def speak(room_name, message, auth)
      room = rooms(auth).find { |r| r["name"] == room_name }
      return unless room

      path = "/room/#{room["id"]}/speak.json"
      body = {
        body: {
          message: {
            type: 'TextMessage',
            body: message
          }
        }
      }
      res = Gitlab::HTTP.post(path, base_uri: base_uri, **auth.merge(body))
      res.code == 201 ? res : nil
    end

    # Returns a list of rooms, or [].
    # https://github.com/basecamp/campfire-api/blob/master/sections/rooms.md#get-rooms
    def rooms(auth)
      res = Gitlab::HTTP.get("/rooms.json", base_uri: base_uri, **auth)
      res.code == 200 ? res["rooms"] : []
    end

    def create_message(push)
      ref = Gitlab::Git.ref_name(push[:ref])
      before = push[:before]
      after = push[:after]

      message = []
      message << "[#{project.full_name}] "
      message << "#{push[:user_name]} "

      if Gitlab::Git.blank_ref?(before)
        message << "pushed new branch #{ref} \n"
      elsif Gitlab::Git.blank_ref?(after)
        message << "removed branch #{ref} \n"
      else
        message << "pushed #{push[:total_commits_count]} commits to #{ref}. "
        message << "#{project.web_url}/compare/#{before}...#{after}"
      end

      message.join
    end
  end
end
