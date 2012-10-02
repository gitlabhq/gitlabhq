admin_credentials = <<-END.gsub(/^ {6}/, '')
  Administrator account created:

  login.........admin@local.host
  password......5iveL!fe
END

if Rails.env.production?
  FactoryGirl.create :admin,
    email: "admin@local.host",
    name: "Administrator",
    password: "5iveL!fe",
    projects_limit: 10_000

  puts admin_credentials
end

if Rails.env.development?
  admin = FactoryGirl.create :admin,
    email: "admin@local.host",
    name: "Administrator",
    password: "5iveL!fe",
    projects_limit: 10_000

  ['Diaspora', 'Rubinius', 'Ruby on Rails'].each do |project_name|
    FactoryGirl.create :project, name: project_name, owner: admin
  end

  8.times { FactoryGirl.create :user }

  project_access = [
    UsersProject::MASTER,
    UsersProject::REPORTER
  ].sample

  User.first(5).each do |user|
    Project.find_each do |project|
      FactoryGirl.create :users_project, user: user, project: project, project_access: project_access
      5.times do
        FactoryGirl.create :issue, author: user, project: project
        FactoryGirl.create :note, author: user, project: project
      end
    end
  end

  puts admin_credentials
end

if Rails.env.test?
  require 'fileutils'

  print "Unpacking seed repository..."

  SEED_REPO = 'seed_project.tar.gz'
  REPO_PATH = Rails.root.join('tmp', 'repositories')

  # Make whatever directories we need to make
  FileUtils.mkdir_p(REPO_PATH)

  # Copy the archive to the repo path
  FileUtils.cp(Rails.root.join('spec', SEED_REPO), REPO_PATH)

  # chdir to the repo path
  FileUtils.cd(REPO_PATH) do
    # Extract the archive
    `tar -xf #{SEED_REPO}`

    # Remove the copy
    FileUtils.rm(SEED_REPO)
  end

  puts ' done.'
end
