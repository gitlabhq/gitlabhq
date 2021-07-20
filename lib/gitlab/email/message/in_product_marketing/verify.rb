# frozen_string_literal: true

module Gitlab
  module Email
    module Message
      module InProductMarketing
        class Verify < Base
          def subject_line
            [
              s_('InProductMarketing|Feel the need for speed?'),
              s_('InProductMarketing|3 ways to dive into GitLab CI/CD'),
              s_('InProductMarketing|Explore the power of GitLab CI/CD')
            ][series]
          end

          def tagline
            [
              s_('InProductMarketing|Use GitLab CI/CD'),
              s_('InProductMarketing|Test, create, deploy'),
              s_('InProductMarketing|Are your runners ready?')
            ][series]
          end

          def title
            [
              s_('InProductMarketing|Rapid development, simplified'),
              s_('InProductMarketing|Get started with GitLab CI/CD'),
              s_('InProductMarketing|Launch GitLab CI/CD in 20 minutes or less')
            ][series]
          end

          def subtitle
            [
              s_('InProductMarketing|How to build and test faster'),
              s_('InProductMarketing|Explore the options'),
              s_('InProductMarketing|Follow our steps')
            ][series]
          end

          def body_line1
            [
              s_("InProductMarketing|Tired of wrestling with disparate tool chains, information silos and inefficient processes? GitLab's CI/CD is built on a DevOps platform with source code management, planning, monitoring and more ready to go. Find out %{ci_link}.") % { ci_link: ci_link },
              s_("InProductMarketing|GitLab's CI/CD makes software development easier. Don't believe us? Here are three ways you can take it for a fast (and satisfying) test drive:"),
              s_("InProductMarketing|Get going with CI/CD quickly using our %{quick_start_link}. Start with an available runner and then create a CI .yml file – it's really that easy.") % { quick_start_link: quick_start_link }
            ][series]
          end

          def body_line2
            [
              nil,
              list([
                s_('InProductMarketing|Start by %{performance_link}').html_safe % { performance_link: performance_link },
                s_('InProductMarketing|Move on to easily creating a Pages website %{ci_template_link}').html_safe % { ci_template_link: ci_template_link },
                s_('InProductMarketing|And finally %{deploy_link} a Python application.').html_safe % { deploy_link: deploy_link }
              ]),
              nil
            ][series]
          end

          def cta_text
            [
              s_('InProductMarketing|Get to know GitLab CI/CD'),
              s_('InProductMarketing|Try it yourself'),
              s_('InProductMarketing|Explore GitLab CI/CD')
            ][series]
          end

          private

          def ci_link
            link(s_('InProductMarketing|how easy it is to get started'), help_page_url('ci/index'))
          end

          def quick_start_link
            link(s_('InProductMarketing|quick start guide'), help_page_url('ci/quick_start/README'))
          end

          def performance_link
            link(s_('InProductMarketing|testing browser performance'), help_page_url('user/project/merge_requests/browser_performance_testing'))
          end

          def ci_template_link
            link(s_('InProductMarketing|using a CI/CD template'), help_page_url('user/project/pages/getting_started/pages_ci_cd_template'))
          end

          def deploy_link
            link(s_('InProductMarketing|test and deploy'), help_page_url('ci/examples/test-and-deploy-python-application-to-heroku'))
          end
        end
      end
    end
  end
end
