FactoryGirl.create :admin,
  email: "admin@local.host",
  name: "Administrator",
  password: "5iveL!fe",
  projects_limit: 10_000

puts <<-END.gsub(/^ {6}/, '')
  Administrator account created:

  login.........admin@local.host
  password......5iveL!fe
END
