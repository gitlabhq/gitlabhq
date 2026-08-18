# frozen_string_literal: true

module Gitlab
  module Mcp
    module Administration
      class VerifyMcpServerSetup
        PASS = "✔"
        FAIL = "✗"
        WARN = "⚠"
        INFO = "ℹ"

        attr_reader :diagnostics

        def initialize(username = nil)
          @username = username
          @user = User.find_by_username(username) if username.present?
          @diagnostics = {}
          @failures = 0
        end

        def execute
          print_header

          collect_system_info
          check_mcp_server_enabled
          check_oauth_discovery

          if @user
            check_user(@user)
          elsif @username.present?
            record(:user_lookup,
              status: :fail,
              message: "User '#{@username}' not found.")
          else
            say "#{INFO} No username provided. Skipping user-specific checks."
            say "  Re-run with: rake gitlab:mcp:verify_setup[username]"
            say
          end

          print_summary
          output_diagnostics
        end

        private

        # Writes a line to stdout. Wraps +puts+ so the CLI output of this
        # diagnostic task doesn't trigger the Rails/Output cop line by line.
        def say(message = '')
          puts message # rubocop:disable Rails/Output -- diagnostic rake task CLI output
        end

        def print_header
          say <<~HEADER

            #{'═' * 63}
            GitLab MCP Server Setup Verification
            #{'═' * 63}
            This task verifies that the MCP server endpoint (/api/v4/mcp)
            is correctly configured and accessible on this instance.

          HEADER
        end

        def print_summary
          say('═' * 63)

          if @failures == 0
            say "#{PASS} All checks passed. MCP server should be functional."
          else
            say "#{FAIL} #{@failures} check(s) failed. MCP server may not work."
          end

          say('═' * 63)
          say
        end

        def record(key, status:, message:, detail: nil)
          passed = status != :fail
          @failures += 1 unless passed

          icon = case status
                 when :pass then PASS
                 when :fail then FAIL
                 when :warn then WARN
                 else INFO
                 end

          say "#{icon} #{message}"
          say "  #{detail}" if detail
          say

          @diagnostics[key] = { status: status.to_s.upcase, message: message, detail: detail }.compact
          passed
        end

        def collect_system_info
          say "Collecting system information..."

          edition = ::Gitlab.ee? ? 'EE' : 'CE'

          @diagnostics[:system] = {
            gitlab_version: ::Gitlab::VERSION,
            gitlab_revision: ::Gitlab.revision,
            gitlab_edition: edition,
            rails_env: Rails.env,
            timestamp: Time.current.iso8601,
            instance_url: ::Gitlab.config.gitlab.url,
            user: @username
          }

          say "  GitLab #{::Gitlab::VERSION} (#{edition}) — #{::Gitlab.config.gitlab.url}"
          say
        end

        def check_mcp_server_enabled
          enabled = ::Gitlab::CurrentSettings.mcp_server_enabled?

          if enabled
            record(:mcp_server_enabled,
              status: :pass,
              message: "mcp_server_enabled: true")
          else
            record(:mcp_server_enabled,
              status: :fail,
              message: "mcp_server_enabled: false",
              detail: "Enable via: Admin > Settings > General > Visibility and access controls > Enable MCP server.")
          end
        end

        def check_oauth_discovery
          base_url = ::Gitlab.config.gitlab.url
          mcp_url = "#{base_url}/api/v4/mcp"

          # MCP is a Grape API endpoint mounted via API::Mcp::Base, not a Rails route.
          # Rails.application.routes.recognize_path cannot detect Grape routes because
          # the Grape API is mounted as a Rack application. Instead, we check that the
          # Grape API class is defined and has registered routes.
          mcp_api_available = defined?(::API::Mcp::Base) &&
            ::API::Mcp::Base.routes.any? { |route| route.path.include?('mcp') }

          if mcp_api_available
            record(:oauth_discovery,
              status: :pass,
              message: "MCP Grape API endpoint is loaded (API::Mcp::Base).",
              detail: "Endpoint: #{mcp_url}\n  " \
                "OAuth discovery: #{base_url}/.well-known/oauth-authorization-server/api/v4/mcp\n  " \
                "Dynamic registration: #{base_url}/oauth/register")
          else
            record(:oauth_discovery,
              status: :fail,
              message: "MCP Grape API endpoint (API::Mcp::Base) is NOT loaded.",
              detail: "This may indicate the MCP module is not loaded.")
          end
        end

        def check_user(user)
          say "--- User-Specific Checks for @#{user.username} (ID: #{user.id}) ---"
          say

          check_user_active(user)
        end

        def check_user_active(user)
          if user.active?
            record(:user_active,
              status: :pass,
              message: "User @#{user.username} is active.")
          else
            record(:user_active,
              status: :fail,
              message: "User @#{user.username} is NOT active (state: #{user.state}).")
          end
        end

        def output_diagnostics
          say
          say('═' * 63)
          say "DIAGNOSTIC SUMMARY (sanitize before sharing with support)"
          say('═' * 63)
          say ::Gitlab::Json.pretty_generate(@diagnostics)
          say
          say "NOTE: Review the above output and remove any sensitive information"
          say "before sharing with GitLab support."
        end
      end
    end
  end
end

Gitlab::Mcp::Administration::VerifyMcpServerSetup.prepend_mod
