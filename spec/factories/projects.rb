# == Schema Information
#
# Table name: projects
#
#  id                     :integer          not null, primary key
#  name                   :string(255)
#  path                   :string(255)
#  description            :text
#  created_at             :datetime
#  updated_at             :datetime
#  creator_id             :integer
#  issues_enabled         :boolean          default(TRUE), not null
#  wall_enabled           :boolean          default(TRUE), not null
#  merge_requests_enabled :boolean          default(TRUE), not null
#  wiki_enabled           :boolean          default(TRUE), not null
#  namespace_id           :integer
#  issues_tracker         :string(255)      default("gitlab"), not null
#  issues_tracker_id      :string(255)
#  snippets_enabled       :boolean          default(TRUE), not null
#  last_activity_at       :datetime
#  import_url             :string(255)
#  visibility_level       :integer          default(0), not null
#  archived               :boolean          default(FALSE), not null
#  import_status          :string(255)
#  repository_size        :float            default(0.0)
#  star_count             :integer          default(0), not null
#

FactoryGirl.define do
  factory :empty_project, class: 'Project' do
    sequence(:name) { |n| "project#{n}" }
    path { name.downcase.gsub(/\s/, '_') }
    namespace
    creator
    snippets_enabled true

    trait :public do
      visibility_level Gitlab::VisibilityLevel::PUBLIC
    end

    trait :internal do
      visibility_level Gitlab::VisibilityLevel::INTERNAL
    end

    trait :private do
      visibility_level Gitlab::VisibilityLevel::PRIVATE
    end
  end

  # Generates a test repository from the repository stored under `spec/seed_project.tar.gz`.
  # Once you run `rake gitlab:setup`, you can see what the repository looks like under `tmp/repositories/gitlabhq`.
  # In order to modify files in the repository, you must untar the seed, modify and remake the tar.
  # Before recompressing, do not forget to `git checkout master`.
  # After recompressing, you need to run `RAILS_ENV=test bundle exec rake gitlab:setup` to regenerate the seeds under tmp.
  #
  # If you want to modify the repository only for an specific type of tests, e.g., markdown tests,
  # consider using a feature branch to reduce the chances of collision with other tests.
  # Create a new commit, and use the same commit message that you will use for the change in the main repo.
  # Changing the commig message and SHA of branch `master` may break tests.
  factory :project, parent: :empty_project do
    path { 'gitlabhq' }

    after :create do |project|
      TestEnv.copy_repo(project)
    end
  end

  factory :redmine_project, parent: :project do
    issues_tracker { "redmine" }
    issues_tracker_id { "project_name_in_redmine" }
  end
end
