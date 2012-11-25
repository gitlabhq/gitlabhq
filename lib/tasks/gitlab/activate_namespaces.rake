namespace :gitlab do
  desc "GITLAB | Enable usernames and namespaces for user projects"
  task activate_namespaces: :environment do
    User.find_each(batch_size: 500) do |user|
      next if user.namespace

      User.transaction do
        username = user.email.match(/^[^@]*/)[0]
        if user.update_attributes!(username: username)
          print '.'.green
        else
          print 'F'.red
        end
      end
    end
  end
end
