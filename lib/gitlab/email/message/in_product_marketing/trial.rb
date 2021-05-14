# frozen_string_literal: true

module Gitlab
  module Email
    module Message
      module InProductMarketing
        class Trial < Base
          def subject_line
            [
              s_('InProductMarketing|Go farther with GitLab'),
              s_('InProductMarketing|Automated security scans directly within GitLab'),
              s_('InProductMarketing|Take your source code management to the next level')
            ][series]
          end

          def tagline
            [
              s_('InProductMarketing|Start a free trial of GitLab Ultimate – no CC required'),
              s_('InProductMarketing|Improve app security with a 30-day trial'),
              s_('InProductMarketing|Start with a GitLab Ultimate free trial')
            ][series]
          end

          def title
            [
              s_('InProductMarketing|Give us one minute...'),
              s_("InProductMarketing|Security that's integrated into your development lifecycle"),
              s_('InProductMarketing|Improve code quality and streamline reviews')
            ][series]
          end

          def subtitle
            [
              s_('InProductMarketing|...and you can get a free trial of GitLab Ultimate'),
              s_('InProductMarketing|Try GitLab Ultimate for free'),
              s_('InProductMarketing|Better code in less time')
            ][series]
          end

          def body_line1
            [
              [
                s_("InProductMarketing|GitLab's premium tiers are designed to make you, your team and your application more efficient and more secure with features including but not limited to:"),
                list([
                  s_('InProductMarketing|%{strong_start}Company wide portfolio management%{strong_end} — including multi-level epics, scoped labels').html_safe % strong_options,
                  s_('InProductMarketing|%{strong_start}Multiple approval roles%{strong_end} — including code owners and required merge approvals').html_safe % strong_options,
                  s_('InProductMarketing|%{strong_start}Advanced application security%{strong_end} — including SAST, DAST scanning, FUZZ testing, dependency scanning, license compliance, secrete detection').html_safe % strong_options,
                  s_('InProductMarketing|%{strong_start}Executive level insights%{strong_end} — including reporting on productivity, tasks by type, days to completion, value stream').html_safe % strong_options
                ])
              ].join("\n"),
              s_('InProductMarketing|GitLab provides static application security testing (SAST), dynamic application security testing (DAST), container scanning, and dependency scanning to help you deliver secure applications along with license compliance.'),
              s_('InProductMarketing|By enabling code owners and required merge approvals the right person will review the right MR. This is a win-win: cleaner code and a more efficient review process.')
            ][series]
          end

          def body_line2
            [
              s_('InProductMarketing|Start a GitLab Ultimate trial today in less than one minute, no credit card required.'),
              s_('InProductMarketing|Get started today with a 30-day GitLab Ultimate trial, no credit card required.'),
              s_('InProductMarketing|Code owners and required merge approvals are part of the paid tiers of GitLab. You can start a free 30-day trial of GitLab Ultimate and enable these features in less than 5 minutes with no credit card required.')
            ][series]
          end

          def cta_text
            [
              s_('InProductMarketing|Start a trial'),
              s_('InProductMarketing|Beef up your security'),
              s_('InProductMarketing|Start your trial now!')
            ][series]
          end
        end
      end
    end
  end
end
