# frozen_string_literal: true

module Gitlab
  module Email
    module Message
      module InProductMarketing
        class Experience < Base
          include Gitlab::Utils::StrongMemoize

          EASE_SCORE_SURVEY_ID = 1

          def subject_line
            s_('InProductMarketing|Do you have a minute?')
          end

          def tagline
          end

          def title
            s_('InProductMarketing|We want your GitLab experience to be great')
          end

          def subtitle
            s_('InProductMarketing|Take this 1-question survey!')
          end

          def body_line1
            s_('InProductMarketing|%{strong_start}Overall, how difficult or easy was it to get started with GitLab?%{strong_end}').html_safe % strong_options
          end

          def body_line2
            s_('InProductMarketing|Click on the number below that corresponds with your answer — 1 being very difficult, 5 being very easy.')
          end

          def cta_text
          end

          def feedback_link(rating)
            params = {
              onboarding_progress: onboarding_progress,
              response: rating,
              show_invite_link: show_invite_link,
              survey_id: EASE_SCORE_SURVEY_ID
            }

            "#{Gitlab::Saas.com_url}/-/survey_responses?#{params.to_query}"
          end

          def feedback_ratings(rating)
            [
              s_('InProductMarketing|Very difficult'),
              s_('InProductMarketing|Difficult'),
              s_('InProductMarketing|Neutral'),
              s_('InProductMarketing|Easy'),
              s_('InProductMarketing|Very easy')
            ][rating - 1]
          end

          def feedback_thanks
            s_('InProductMarketing|Feedback from users like you really improves our product. Thanks for your help!')
          end

          private

          def onboarding_progress
            strong_memoize(:onboarding_progress) do
              group.onboarding_progress.number_of_completed_actions
            end
          end

          def show_invite_link
            strong_memoize(:show_invite_link) do
              group.member_count > 1 && group.max_member_access_for_user(user) >= GroupMember::DEVELOPER && user.preferred_language == 'en'
            end
          end
        end
      end
    end
  end
end
