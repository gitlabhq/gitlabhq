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
    sha '97de212e80737a608d939f648d959671fb0a0142'

    gl_project factory: :empty_project

    factory :ci_commit_without_jobs do
      after(:create) do |commit, evaluator|
        allow(commit).to receive(:ci_yaml_file) { YAML.dump({}) }
      end
    end

    factory :ci_commit_with_one_job do
      after(:create) do |commit, evaluator|
        allow(commit).to receive(:ci_yaml_file) { YAML.dump({ rspec: { script: "ls" } }) }
      end
    end

    factory :ci_commit_with_two_jobs do
      after(:create) do |commit, evaluator|
        allow(commit).to receive(:ci_yaml_file) { YAML.dump({ rspec: { script: "ls" }, spinach: { script: "ls" } }) }
      end
    end
  end
end
