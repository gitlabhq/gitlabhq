require './spec/support/sidekiq_middleware'


# Creating keys runs a gitlab-shell worker. Since we may not have the right
# gitlab-shell path set (yet) we need to disable this for these fixtures.
Sidekiq::Testing.disable! do
  Gitlab::Seeder.quiet do
    # We want to run `add_to_authorized_keys` immediately instead of after the commit, so
    # that it falls under `Sidekiq::Testing.disable!`.
    Key.skip_callback(:commit, :after, :add_to_authorized_keys)

    User.not_mass_generated.first(10).each do |user|
      key = "ssh-rsa AAAAB3NzaC1yc2EAAAABJQAAAIEAiPWx6WM4lhHNedGfBpPJNPpZ7yKu+dnn1SJejgt#{user.id + 100}6k6YjzGGphH2TUxwKzxcKDKKezwkpfnxPkSMkuEspGRt/aZZ9wa++Oi7Qkr8prgHc4soW6NUlfDzpvZK2H5E7eQaSeP3SAwGmQKUFHCddNaP0L+hM7zhFNzjFvpaMgJw0="

      key = user.keys.create(
        title: "Sample key #{user.id}",
        key: key
      )

      Sidekiq::Worker.skipping_transaction_check do
        key.add_to_authorized_keys
      end

      print '.'
    end
  end
end
