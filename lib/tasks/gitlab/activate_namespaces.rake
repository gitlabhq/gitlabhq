namespace :gitlab do
  desc "GITLAB | Enable usernames and namespaces for user projects"
  task activate_namespaces: :environment do
    User.find_each(batch_size: 500) do |user|
      User.transaction do
        username = user.email.match(/^[^@]*/)[0]
        user.update_attributes!(username: username)
        user.create_namespace!(code: username, name: user.name)
        print '.'.green
      end
    end
  end
end
