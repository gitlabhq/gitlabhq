# frozen_string_literal: true

module Gitlab
  module Email
    module Message
      module InProductMarketing
        class InviteTeam < Base
          def subject_line
            s_('InProductMarketing|Invite your teammates to GitLab')
          end

          def tagline
            ''
          end

          def title
            s_('InProductMarketing|GitLab is better with teammates to help out!')
          end

          def subtitle
            ''
          end

          def body_line1
            s_('InProductMarketing|Invite your teammates today and build better code together. You can even assign tasks to new teammates such as setting up CI/CD, to help get projects up and running.')
          end

          def body_line2
            ''
          end

          def cta_text
            s_('InProductMarketing|Invite your teammates to help')
          end

          def logo_path
            'mailers/in_product_marketing/team-0.png'
          end

          def series?
            false
          end

          private

          def validate_series!
            raise ArgumentError, "Only one email is sent for this track. Value of `series` should be 0." unless @series == 0
          end
        end
      end
    end
  end
end
