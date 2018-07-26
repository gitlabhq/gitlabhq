# frozen_string_literal: true

module EE
  module API
    module Projects
      extend ActiveSupport::Concern

      prepended do
        helpers do
          params :optional_filter_params_ee do
            optional :wiki_checksum_failed, type: Grape::API::Boolean, default: false, desc: 'Limit by projects where wiki checksum is failed'
            optional :repository_checksum_failed, type: Grape::API::Boolean, default: false, desc: 'Limit by projects where repository checksum is failed'
          end

          params :optional_update_params_ee do
            optional :mirror_user_id, type: Integer, desc: 'User responsible for all the activity surrounding a pull mirror event'
            optional :only_mirror_protected_branches, type: Grape::API::Boolean, desc: 'Only mirror protected branches'
            optional :mirror_overwrites_diverged_branches, type: Grape::API::Boolean, desc: 'Pull mirror overwrites diverged branches'
            optional :import_url, type: String, desc: 'URL from which the project is imported'
          end

          def apply_filters(projects)
            projects = super(projects)
            projects = projects.verification_failed_wikis if params[:wiki_checksum_failed]
            projects = projects.verification_failed_repos if params[:repository_checksum_failed]

            projects
          end
        end
      end

      class_methods do
        def update_params_at_least_one_of
          super.concat [
            :approvals_before_merge,
            :repository_storage,
            :external_authorization_classification_label,
            :import_url
          ]
        end
      end
    end
  end
end
