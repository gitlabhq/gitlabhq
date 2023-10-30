# frozen_string_literal: true

module API
  module Internal
    class Shellhorse < ::API::Base
      before { authenticate_by_gitlab_shell_or_workhorse_token! }

      helpers ::API::Helpers::InternalHelpers

      COMMANDS_TO_AUDIT = %w[git-upload-pack git-receive-pack].freeze

      helpers do
        def check_clone_or_pull_or_push_verb(params)
          return 'push' if params[:action] == 'git-receive-pack'

          # we must set the default value for wants/haves because
          # gitlab shell/workhorse will trim the whole posted params
          # json key if its value is 0
          wants = haves = 0
          if params.key?(:packfile_stats)
            wants = Integer(params[:packfile_stats][:wants]) if params[:packfile_stats][:wants].present?
            haves = Integer(params[:packfile_stats][:haves]) if params[:packfile_stats][:haves].present?
          end

          wants > 0 && haves == 0 ? 'clone' : 'pull'
        end
      end

      namespace 'internal' do
        namespace 'shellhorse' do
          params do
            requires :action, type: String
            requires :protocol, type: String
            requires :gl_repository, type: String # repository identifier, such as project-7
            optional :packfile_stats, type: Hash do
              # wants is the number of objects the client announced it wants.
              optional :wants, type: Integer
              # haves is the number of objects the client announced it has.
              optional :haves, type: Integer
            end
          end

          post '/git_audit_event', feature_category: :source_code_management do
            unless COMMANDS_TO_AUDIT.include?(params[:action])
              break response_with_status(code: 400, success: false, message: "No valid action specified")
            end

            check_result = access_check_result
            break check_result if unsuccessful_response?(check_result)

            unless need_git_audit_event?
              break response_with_status(code: 200, success: false, message: "No git audit event needed")
            end

            unless check_result.is_a?(::Gitlab::GitAccessResult::Success)
              break response_with_status(code: 500, success: false,
                message: ::API::Helpers::InternalHelpers::UNKNOWN_CHECK_RESULT_ERROR)
            end

            msg = {
              protocol: params[:protocol],
              action: params[:action],
              verb: check_clone_or_pull_or_push_verb(params)
            }
            send_git_audit_streaming_event(msg)
            response_with_status(message: msg)
          end
        end
      end
    end
  end
end

API::Internal::Shellhorse.prepend_mod_with('API::Internal::Shellhorse')
