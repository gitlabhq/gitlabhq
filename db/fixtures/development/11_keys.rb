require './spec/support/sidekiq'

# Creating keys runs a gitlab-shell worker. Since we may not have the right
# gitlab-shell path set (yet) we need to disable this for these fixtures.
Sidekiq::Testing.disable! do
  Gitlab::Seeder.quiet do
    User.first(10).each do |user|
      key = "ssh-rsa AAAAB3NzaC1yc2EAAAABJQAAAIEAiPWx6WM4lhHNedGfBpPJNPpZ7yKu+dnn1SJejgt#{user.id + 100}6k6YjzGGphH2TUxwKzxcKDKKezwkpfnxPkSMkuEspGRt/aZZ9wa++Oi7Qkr8prgHc4soW6NUlfDzpvZK2H5E7eQaSeP3SAwGmQKUFHCddNaP0L+hM7zhFNzjFvpaMgJw0="

      user.keys.create(
        title: "Sample key #{user.id}",
        key: key
      )

      print '.'
    end
  end
end
