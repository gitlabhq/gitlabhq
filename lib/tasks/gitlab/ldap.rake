namespace :gitlab do
  namespace :ldap do
    desc 'GitLab | LDAP | Rename provider'
    task :rename_provider, [:old_provider, :new_provider] => :environment  do |_, args|
      old_provider = args[:old_provider] ||
        prompt('What is the old provider? Ex. \'ldapmain\': '.color(:blue))
      new_provider = args[:new_provider] ||
        prompt('What is the new provider ID? Ex. \'ldapcustom\': '.color(:blue))
      puts '' # Add some separation in the output

      identities = Identity.where(provider: old_provider)
      identity_count = identities.count

      if identities.empty?
        puts "Found no user identities with '#{old_provider}' provider."
        puts 'Please check the provider name and try again.'
        exit 1
      end

      plural_id_count = ActionController::Base.helpers.pluralize(identity_count, 'user')

      unless ENV['force'] == 'yes'
        puts "#{plural_id_count} with provider '#{old_provider}' will be updated to '#{new_provider}'"
        puts 'If the new provider is incorrect, users will be unable to sign in'
        ask_to_continue
        puts ''
      end

      updated_count = identities.update_all(provider: new_provider)

      if updated_count == identity_count
        puts 'User identities were successfully updated'.color(:green)
      else
        plural_updated_count = ActionController::Base.helpers.pluralize(updated_count, 'user')
        puts 'Some user identities could not be updated'.color(:red)
        puts "Successfully updated #{plural_updated_count} out of #{plural_id_count} total"
      end
    end

    desc "GitLab | LDAP | Generate avatar file for every user using their photo stored in LDAP"
    task generate_avatars: :environment  do |t, args|

      if Gitlab::LDAP::Config.enabled?
        generate_user_avatar_from_ldap
      else
        puts 'LDAP is disabled in config/gitlab.yml'
      end
    end

    def generate_user_avatar_from_ldap
      servers = Gitlab::LDAP::Config.providers
      servers.each do |server|
        puts "Currently querying LDAP server: #{server}"
        begin
          Gitlab::LDAP::Adapter.open(server) do |adapter|
            puts "Iterating over your LDAP users who have access to your GitLab server"
            users = adapter.users(adapter.config.uid, '*')
            users.each do |user|
              puts "Processing user with #{adapter.config.uid} #{user.uid} (DN: #{user.dn})..."
              if gl_user = User.find_by_email(user.email)
                avatar_path = "#{Rails.root}/public/uploads/user/avatar/#{gl_user.id}"
                unless Dir.exist?(avatar_path)
                  puts "\tAvatar directory #{avatar_path} does not exist, creating it"
                  FileUtils.mkdir_p avatar_path
                end
                if user.photo[0]
                  puts "\tFound photo in LDAP, saving it under ldap_avatar.jpg"
                  fb = File.open('/tmp/ldap_avatar.jpg', 'wb')
                  fb.write user.photo[0]
                  fb.close
                  if gl_user.avatar.model.avatar.to_s.empty?
                    puts "\tNo personal avatar found, using LDAP photo as avatar"
                    gl_user.avatar = File.open('/tmp/ldap_avatar.jpg')
                    gl_user.save!
                  end
                  File.unlink('/tmp/ldap_avatar.jpg')
                else
                  puts "\tNo photo found in LDAP"
                end
              else
                puts "\tLDAP user does not exist yet in gitlab, skipping"
              end
              puts
            end
          end
        rescue Net::LDAP::ConnectionRefusedError, Errno::ECONNREFUSED => e
          puts "Could not connect to the LDAP server: #{e.message}".color(:red)
        end
      end
    end
  end
end
