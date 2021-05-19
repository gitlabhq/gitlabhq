# frozen_string_literal: true

module Gitlab
  module Email
    module Message
      module InProductMarketing
        class Team < Base
          def subject_line
            [
              s_('InProductMarketing|Working in GitLab = more efficient'),
              s_("InProductMarketing|Multiple owners, confusing workstreams? We've got you covered"),
              s_('InProductMarketing|Your teams can be more efficient')
            ][series]
          end

          def tagline
            [
              s_('InProductMarketing|Invite your colleagues to join in less than one minute'),
              s_('InProductMarketing|Get your team set up on GitLab'),
              nil
            ][series]
          end

          def title
            [
              s_('InProductMarketing|Team work makes the dream work'),
              s_('InProductMarketing|*GitLab*, noun: a synonym for efficient teams'),
              s_('InProductMarketing|Find out how your teams are really doing')
            ][series]
          end

          def subtitle
            [
              s_('InProductMarketing|Actually, GitLab makes the team work (better)'),
              s_('InProductMarketing|Our tool brings all the things together'),
              s_("InProductMarketing|It's all in the stats")
            ][series]
          end

          def body_line1
            [
              [
                s_('InProductMarketing|Did you know teams that use GitLab are far more efficient?'),
                list([
                  s_('InProductMarketing|Goldman Sachs went from 1 build every two weeks to thousands of builds a day'),
                  s_('InProductMarketing|Ticketmaster decreased their CI build time by 15X')
                ])
              ].join("\n"),
              s_("InProductMarketing|We know a thing or two about efficiency and we don't want to keep that to ourselves. Sign up for a free trial of GitLab Ultimate and your teams will be on it from day one."),
              [
                s_('InProductMarketing|Stop wondering and use GitLab to answer questions like:'),
                list([
                  s_('InProductMarketing|How long does it take us to close issues/MRs by types like feature requests, bugs, tech debt, security?'),
                  s_('InProductMarketing|How many days does it take our team to complete various tasks?'),
                  s_('InProductMarketing|What does our value stream timeline look like from product to development to review and production?')
                ])
              ].join("\n")
            ][series]
          end

          def body_line2
            [
              s_('InProductMarketing|Invite your colleagues and start shipping code faster.'),
              s_("InProductMarketing|Streamline code review, know at a glance who's unavailable, communicate in comments or in email and integrate with Slack so everyone's on the same page."),
              s_('InProductMarketing|When your team is on GitLab these answers are a click away.')
            ][series]
          end

          def cta_text
            [
              s_('InProductMarketing|Invite your colleagues today'),
              s_('InProductMarketing|Invite your team in less than 60 seconds'),
              s_('InProductMarketing|Invite your team now')
            ][series]
          end
        end
      end
    end
  end
end
