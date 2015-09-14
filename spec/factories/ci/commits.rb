# == Schema Information
#
# Table name: commits
#
#  id           :integer          not null, primary key
#  project_id   :integer
#  ref          :string(255)
#  sha          :string(255)
#  before_sha   :string(255)
#  push_data    :text
#  created_at   :datetime
#  updated_at   :datetime
#  tag          :boolean          default(FALSE)
#  yaml_errors  :text
#  committed_at :datetime
#

# Read about factories at https://github.com/thoughtbot/factory_girl
FactoryGirl.define do
  factory :ci_commit, class: Ci::Commit do
    ref 'master'
    before_sha '76de212e80737a608d939f648d959671fb0a0142'
    sha '97de212e80737a608d939f648d959671fb0a0142'
    push_data do
      {
        ref: 'refs/heads/master',
        before: '76de212e80737a608d939f648d959671fb0a0142',
        after: '97de212e80737a608d939f648d959671fb0a0142',
        user_name: 'Git User',
        user_email: 'git@example.com',
        repository: {
          name: 'test-data',
          url: 'ssh://git@gitlab.com/test/test-data.git',
          description: '',
          homepage: 'http://gitlab.com/test/test-data'
        },
        commits: [
          {
            id: '97de212e80737a608d939f648d959671fb0a0142',
            message: 'Test commit message',
            timestamp: '2014-09-23T13:12:25+02:00',
            url: 'https://gitlab.com/test/test-data/commit/97de212e80737a608d939f648d959671fb0a0142',
            author: {
              name: 'Git User',
              email: 'git@user.com'
            }
          }
        ],
        total_commits_count: 1,
        ci_yaml_file: File.read(Rails.root.join('spec/support/gitlab_stubs/gitlab_ci.yml'))
      }
    end

    factory :ci_commit_without_jobs do
      after(:create) do |commit, evaluator|
        commit.push_data[:ci_yaml_file] = YAML.dump({})
        commit.save
      end
    end

    factory :ci_commit_with_one_job do
      after(:create) do |commit, evaluator|
        commit.push_data[:ci_yaml_file] = YAML.dump({ rspec: { script: "ls" } })
        commit.save
      end
    end

    factory :ci_commit_with_two_jobs do
      after(:create) do |commit, evaluator|
        commit.push_data[:ci_yaml_file] = YAML.dump({ rspec: { script: "ls" }, spinach: { script: "ls" } })
        commit.save
      end
    end
  end
end
