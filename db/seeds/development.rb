# create user with admin rights
admin = FactoryGirl.create :admin,
  email: "admin@local.host",
  name: "Administrator",
  password: "5iveL!fe",
  projects_limit: 10_000

# create projects
['Diaspora', 'Rubinius', 'Ruby on Rails'].each do |project_name|
  FactoryGirl.create :project, name: project_name, owner: admin
end

# create users
8.times { FactoryGirl.create :user }

project_access = [
  UsersProject::MASTER,
  UsersProject::REPORTER
].sample

User.first(5).each do |user|
  Project.find_each do |project|
    # Add first 5 users to each project
    # with random access level (MASTER or REPORTER)
    FactoryGirl.create :users_project, user: user, project: project, project_access: project_access

    # create 5 times issues and wall notes by first 5 users in each project
    5.times do
      FactoryGirl.create :issue, author: user, project: project
      FactoryGirl.create :note, author: user, project: project
    end
  end
end

puts <<-END.gsub(/^ {6}/, '')
  Administrator account created:

  login.........admin@local.host
  password......5iveL!fe
END
