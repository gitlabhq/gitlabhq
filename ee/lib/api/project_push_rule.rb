module API
  class ProjectPushRule < Grape::API
    before { authenticate! }
    before { authorize_admin_project }
    before { check_project_feature_available!(:push_rules) }

    params do
      requires :id, type: String, desc: 'The ID of a project'
    end
    resource :projects do
      helpers do
        params :push_rule_params do
          optional :deny_delete_tag, type: Boolean, desc: 'Deny deleting a tag'
          optional :member_check, type: Boolean, desc: 'Restrict commits by author (email) to existing GitLab users'
          optional :prevent_secrets, type: Boolean, desc: 'GitLab will reject any files that are likely to contain secrets'
          optional :commit_message_regex, type: String, desc: 'All commit messages must match this'
          optional :branch_name_regex, type: String, desc: 'All branches names must match this'
          optional :author_email_regex, type: String, desc: 'All commit author emails must match this'
          optional :file_name_regex, type: String, desc: 'All commited filenames must not match this'
          optional :max_file_size, type: Integer, desc: 'Maximum file size (MB)'
          at_least_one_of :deny_delete_tag, :member_check, :prevent_secrets,
                          :commit_message_regex, :branch_name_regex, :author_email_regex,
                          :file_name_regex, :max_file_size
        end
      end

      desc 'Get project push rule' do
        success Entities::ProjectPushRule
      end
      get ":id/push_rule" do
        push_rule = user_project.push_rule
        present push_rule, with: Entities::ProjectPushRule
      end

      desc 'Add a push rule to a project' do
        success Entities::ProjectPushRule
      end
      params do
        use :push_rule_params
      end
      post ":id/push_rule" do
        if user_project.push_rule
          error!("Project push rule exists", 422)
        else
          push_rule = user_project.create_push_rule(declared_params(include_missing: false))
          present push_rule, with: Entities::ProjectPushRule
        end
      end

      desc 'Update an existing project push rule' do
        success Entities::ProjectPushRule
      end
      params do
        use :push_rule_params
      end
      put ":id/push_rule" do
        push_rule = user_project.push_rule
        not_found!('Push Rule') unless push_rule

        if push_rule.update_attributes(declared_params(include_missing: false))
          present push_rule, with: Entities::ProjectPushRule
        else
          render_validation_error!(push_rule)
        end
      end

      desc 'Deletes project push rule'
      delete ":id/push_rule" do
        push_rule = user_project.push_rule
        not_found!('Push Rule') unless push_rule

        push_rule.destroy
        status 204
      end
    end
  end
end
