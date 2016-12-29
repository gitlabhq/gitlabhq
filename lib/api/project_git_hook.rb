# TODO: These end-points are deprecated and replaced with push_rules
# and should be removed after  GitLab 9.0 is released

module API
  # Projects push rule API
  class ProjectGitHook < Grape::API
    before { authenticate! }
    before { authorize_admin_project }

    DEPRECATION_MESSAGE = 'This endpoint is deprecated, replaced with push_rules, and will be removed in GitLab 9.0.'.freeze

    params do
      requires :id, type: String, desc: 'The ID of a project'
    end
    resource :projects do
      helpers do
        params :push_rule_params do
          optional :commit_message_regex, type: String, desc: 'The commit message regex'
          optional :deny_delete_tag, type: Boolean, desc: 'Deny deleting a tag'
          at_least_one_of :commit_message_regex, :deny_delete_tag
        end
      end

      desc 'Get project push rule' do
        success Entities::ProjectPushRule
        detail DEPRECATION_MESSAGE
      end
      get ":id/git_hook" do
        push_rule = user_project.push_rule
        present push_rule, with: Entities::ProjectPushRule
      end

      desc 'Add a push rule to a project' do
        success Entities::ProjectPushRule
        detail DEPRECATION_MESSAGE
      end
      params do
        use :push_rule_params
      end
      post ":id/git_hook" do
        if user_project.push_rule
          error!("Project push rule exists", 422)
        else
          push_rule = user_project.create_push_rule(declared_params)
          present push_rule, with: Entities::ProjectPushRule
        end
      end

      desc 'Update an existing project push rule' do
        success Entities::ProjectPushRule
        detail DEPRECATION_MESSAGE
      end
      params do
        use :push_rule_params
      end
      put ":id/git_hook" do
        push_rule = user_project.push_rule
        not_found!('Push Rule') unless push_rule

        if push_rule.update_attributes(declared_params(include_missing: false))
          present push_rule, with: Entities::ProjectPushRule
        else
          render_validation_error!(push_rule)
        end
      end

      desc 'Deletes project push rule' do
        detail DEPRECATION_MESSAGE
      end
      delete ":id/git_hook" do
        push_rule = user_project.push_rule
        not_found!('Push Rule') unless push_rule

        push_rule.destroy
      end
    end
  end
end
