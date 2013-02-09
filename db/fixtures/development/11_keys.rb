
Gitlab::Seeder.quiet do
  User.first(30).each_with_index do |user, i|
    Key.seed(:id, [
      {
        id: i,
        title: "Sample key #{i}",
        key: "ssh-rsa AAAAB3NzaC1yc2EAAAABJQAAAIEAiPWx6WM4lhHNedGfBpPJNPpZ7yKu+dnn1SJejgt#{i + 100}6k6YjzGGphH2TUxwKzxcKDKKezwkpfnxPkSMkuEspGRt/aZZ9wa++Oi7Qkr8prgHc4soW6NUlfDzpvZK2H5E7eQaSeP3SAwGmQKUFHCddNaP0L+hM7zhFNzjFvpaMgJw0=",
        user_id: user.id,
      }
    ])
    puts "SSH KEY ##{i} added.".green
  end
end
