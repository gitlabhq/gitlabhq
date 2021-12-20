# frozen_string_literal: true

module Gitlab
  module Email
    module Message
      module InProductMarketing
        class AdminVerify < Base
          def subject_line
            s_('InProductMarketing|Create a custom CI runner with just a few clicks')
          end

          def tagline
            nil
          end

          def title
            s_('InProductMarketing|Spin up an autoscaling runner in GitLab')
          end

          def subtitle
            s_('InProductMarketing|Use our AWS cloudformation template to spin up your runners in just a few clicks!')
          end

          def body_line1
            ''
          end

          def body_line2
            ''
          end

          def cta_text
            s_('InProductMarketing|Create a custom runner')
          end

          def progress
            super(track_name: 'Admin')
          end

          def invite_members?
            user.can?(:admin_group_member, group)
          end
        end
      end
    end
  end
end
