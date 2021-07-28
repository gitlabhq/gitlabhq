# frozen_string_literal: true

module Gitlab
  module Email
    module Message
      module InProductMarketing
        class TeamShort < Base
          def subject_line
            s_('InProductMarketing|Team up in GitLab for greater efficiency')
          end

          def tagline
            nil
          end

          def title
            s_('InProductMarketing|Turn coworkers into collaborators')
          end

          def subtitle
            s_('InProductMarketing|Invite your team today to build better code (and processes) together')
          end

          def body_line1
            ''
          end

          def body_line2
            ''
          end

          def cta_text
            s_('InProductMarketing|Invite your colleagues today')
          end

          def progress
            super(total: 4, track_name: 'Team')
          end

          def logo_path
            'mailers/in_product_marketing/team-0.png'
          end
        end
      end
    end
  end
end
