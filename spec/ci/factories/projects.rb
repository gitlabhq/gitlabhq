# == Schema Information
#
# Table name: projects
#
#  id                       :integer          not null, primary key
#  name                     :string(255)      not null
#  timeout                  :integer          default(3600), not null
#  created_at               :datetime
#  updated_at               :datetime
#  token                    :string(255)
#  default_ref              :string(255)
#  path                     :string(255)
#  always_build             :boolean          default(FALSE), not null
#  polling_interval         :integer
#  public                   :boolean          default(FALSE), not null
#  ssh_url_to_repo          :string(255)
#  gitlab_id                :integer
#  allow_git_fetch          :boolean          default(TRUE), not null
#  email_recipients         :string(255)      default(""), not null
#  email_add_pusher         :boolean          default(TRUE), not null
#  email_only_broken_builds :boolean          default(TRUE), not null
#  skip_refs                :string(255)
#  coverage_regex           :string(255)
#  shared_runners_enabled   :boolean          default(FALSE)
#  generated_yaml_config    :text
#

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :project_without_token, class: Project do
    sequence :name do |n|
      "GitLab / gitlab-shell#{n}"
    end

    default_ref 'master'

    sequence :path do |n|
      "gitlab/gitlab-shell#{n}"
    end

    sequence :ssh_url_to_repo do |n|
      "git@demo.gitlab.com:gitlab/gitlab-shell#{n}.git"
    end

    sequence :gitlab_id

    factory :project do
      token 'iPWx6WM4lhHNedGfBpPJNP'
    end

    factory :public_project do
      public true
    end
  end
end
