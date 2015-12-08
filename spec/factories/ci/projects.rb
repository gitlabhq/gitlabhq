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
  factory :ci_project_without_token, class: Ci::Project do
    default_ref 'master'

    shared_runners_enabled false

    factory :ci_project do
      token 'iPWx6WM4lhHNedGfBpPJNP'
    end

    initialize_with do
      # TODO:
      # this is required, because builds_enabled is initialized when Project is created
      # and this create gitlab_ci_project if builds is set to true
      # here we take created gitlab_ci_project and update it's attributes
      ci_project = create(:empty_project).ensure_gitlab_ci_project
      ci_project.update_attributes(attributes)
      ci_project
    end
  end
end
