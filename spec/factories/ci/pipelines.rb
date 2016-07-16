# == Schema Information
#
# Table name: commits
#
#  id             :integer          not null, primary key
#  project_id     :integer
#  ref            :string(255)
#  sha            :string(255)
#  before_sha     :string(255)
#  push_data      :text
#  created_at     :datetime
#  updated_at     :datetime
#  tag            :boolean          default(FALSE)
#  yaml_errors    :text
#  committed_at   :datetime
#  gl_project_id  :integer
#

FactoryGirl.define do
  factory :ci_empty_pipeline, class: Ci::Pipeline do
    ref 'master'
    sha '97de212e80737a608d939f648d959671fb0a0142'
    status 'pending'

    project factory: :empty_project

    factory :ci_pipeline_without_jobs do
      after(:build) do |commit|
        allow(commit).to receive(:ci_yaml_file) { YAML.dump({}) }
      end
    end

    factory :ci_pipeline_with_one_job do
      after(:build) do |commit|
        allow(commit).to receive(:ci_yaml_file) { YAML.dump({ rspec: { script: "ls" } }) }
      end
    end

    factory :ci_pipeline_with_two_job do
      after(:build) do |commit|
        allow(commit).to receive(:ci_yaml_file) { YAML.dump({ rspec: { script: "ls" }, spinach: { script: "ls" } }) }
      end
    end

    factory :ci_pipeline do
      after(:build) do |commit|
        allow(commit).to receive(:ci_yaml_file) { File.read(Rails.root.join('spec/support/gitlab_stubs/gitlab_ci.yml')) }
      end
    end
  end
end
