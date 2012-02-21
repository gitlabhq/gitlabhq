require File.join(Rails.root, 'spec', 'factory')

Factory.add(:project, Project) do |obj|
  obj.name = Faker::Internet.user_name
  obj.path = 'legit'
  obj.owner = Factory(:user)
  obj.code = 'LGT'
end

Factory.add(:public_project, Project) do |obj|
  obj.name = Faker::Internet.user_name
  obj.path = 'legit'
  obj.private_flag = false
  obj.owner = Factory(:user)
  obj.code = 'LGT'
end

Factory.add(:user, User) do |obj|
  obj.email = Faker::Internet.email
  obj.password = "123456"
  obj.name = Faker::Name.name
  obj.password_confirmation = "123456"
end

Factory.add(:admin, User) do |obj|
  obj.email = Faker::Internet.email
  obj.password = "123456"
  obj.name = Faker::Name.name
  obj.password_confirmation = "123456"
  obj.admin = true
end

Factory.add(:issue, Issue) do |obj|
  obj.title = Faker::Lorem.sentence
end

Factory.add(:merge_request, MergeRequest) do |obj|
  obj.title = Faker::Lorem.sentence
  obj.source_branch = "master"
  obj.target_branch = "master"
  obj.closed = false
end

Factory.add(:snippet, Snippet) do |obj|
  obj.title = Faker::Lorem.sentence
  obj.file_name = Faker::Lorem.sentence
  obj.content = Faker::Lorem.sentences
end

Factory.add(:note, Note) do |obj|
  obj.note = Faker::Lorem.sentence
end

Factory.add(:key, Key) do |obj|
  obj.title = "Example key"
  obj.key = File.read(File.join(Rails.root, "db", "pkey.example"))
end

Factory.add(:web_hook, WebHook) do |obj|
  obj.url = Faker::Internet.url
end

Factory.add(:wikis, WebHook) do |obj|
  obj.title = Faker::Lorem.sentence
  obj.content = Faker::Lorem.sentence
end
