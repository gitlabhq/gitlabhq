# frozen_string_literal: true

module Gitlab
  module Email
    module Message
      module InProductMarketing
        class TrialShort < Base
          def subject_line
            s_('InProductMarketing|Be a DevOps hero')
          end

          def tagline
            nil
          end

          def title
            s_('InProductMarketing|Expand your DevOps journey with a free GitLab trial')
          end

          def subtitle
            s_('InProductMarketing|Start your trial today to experience single application success and discover all the features of GitLab Ultimate for free!')
          end

          def body_line1
            ''
          end

          def body_line2
            ''
          end

          def cta_text
            s_('InProductMarketing|Start a trial')
          end

          def progress
            super(total: 4, track_name: 'Trial')
          end

          def logo_path
            'mailers/in_product_marketing/trial-0.png'
          end
        end
      end
    end
  end
end
