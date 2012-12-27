User.seed(:id, [
  {
    id: 1,
    name: "Administrator",
    email: "admin@local.host",
    username: 'root',
    password: "5iveL!fe",
    password_confirmation: "5iveL!fe",
    admin: true,
  }
])


Key.seed(:id, [
  {
    id: 1,
    title: "Sample key",
    key: "ssh-rsa AAAAB3NzaC1yc2EAAAABJQAAAIEAiPWx6WM4lhHNedGfBpPJNPpZ7yKu+dnn1SJejgt4596k6YjzGGphH2TUxwKzxcKDKKezwkpfnxPkSMkuEspGRt/aZZ9wa++Oi7Qkr8prgHc4soW6NUlfDzpvZK2H5E7eQaSeP3SAwGmQKUFHCddNaP0L+hM7zhFNzjFvpaMgJw0=",
    user_id: 1,
  }
])
