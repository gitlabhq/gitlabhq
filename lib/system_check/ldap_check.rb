# frozen_string_literal: true

module SystemCheck
  # Used by gitlab:ldap:check rake task
  class LdapCheck < BaseCheck
    set_name 'LDAP:'

    def multi_check
      if Gitlab::Auth::Ldap::Config.enabled?
        # Only show up to 100 results because LDAP directories can be very big.
        # This setting only affects the `rake gitlab:check` script.
        limit = ENV['LDAP_CHECK_LIMIT']
        limit = 100 if limit.blank?

        check_ldap(limit)
      else
        $stdout.puts 'LDAP is disabled in config/gitlab.yml'
      end
    end

    private

    def check_ldap(limit)
      servers = Gitlab::Auth::Ldap::Config.providers

      servers.each do |server|
        $stdout.puts "Server: #{server}"

        begin
          Gitlab::Auth::Ldap::Adapter.open(server) do |adapter|
            check_ldap_auth(adapter)

            $stdout.puts "LDAP users with access to your GitLab server (only showing the first #{limit} results)"

            users = adapter.users(adapter.config.uid, '*', limit)

            if should_sanitize?
              $stdout.puts "\tUser output sanitized. Found #{users.length} users of #{limit} limit."
            else
              users.each do |user|
                $stdout.puts "\tDN: #{user.dn}\t #{adapter.config.uid}: #{user.uid}"
              end
            end
          end
        rescue Errno::ECONNREFUSED => e
          $stdout.puts Rainbow("Could not connect to the LDAP server: #{e.message}").red
        end
      end
    end

    def check_ldap_auth(adapter)
      auth = adapter.config.has_auth?

      message = if auth && adapter.ldap.bind
                  Rainbow('Success').green
                elsif auth
                  Rainbow('Failed. Check `bind_dn` and `password` configuration values').red
                else
                  Rainbow('Anonymous. No `bind_dn` or `password` configured').yellow
                end

      $stdout.puts "LDAP authentication... #{message}"
    end
  end
end
