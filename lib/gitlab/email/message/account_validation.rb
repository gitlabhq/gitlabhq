# frozen_string_literal: true

module Gitlab
  module Email
    module Message
      class AccountValidation
        include Gitlab::Email::Message::InProductMarketing::Helper
        include Gitlab::Routing

        attr_accessor :pipeline, :format

        def initialize(pipeline, format: :html)
          @pipeline = pipeline
          @format = format
        end

        def subject_line
          s_('AccountValidation|Fix your pipelines by validating your account')
        end

        def title
          s_("AccountValidation|Looks like you’ll need to validate your account to use free pipeline minutes")
        end

        def body_line1
          s_("AccountValidation|In order to use free pipeline minutes on shared runners, you'll need to validate your account with a credit or debit card. If you prefer not to provide one, you can run pipelines by bringing your own runners and disabling shared runners for your project.")
        end

        def body_line2
          format_options = strong_options.merge({ learn_more_link: learn_more_link })
          s_("AccountValidation|This is required to discourage and reduce the abuse on GitLab infrastructure. %{strong_start}GitLab will not charge or store your card, it will only be used for validation.%{strong_end} %{learn_more_link}").html_safe % format_options
        end

        def cta_text
          s_('AccountValidation|Validate your account')
        end

        def cta2_text
          s_("AccountValidation|I'll bring my own runners")
        end

        def logo_path
          'mailers/in_product_marketing/verify-2.png'
        end

        def cta_link
          url = project_pipeline_url(pipeline.project, pipeline)

          case format
          when :html
            ActionController::Base.helpers.link_to cta_text, url, target: '_blank', rel: 'noopener noreferrer'
          else
            [cta_text, url].join(' >> ')
          end
        end

        def cta2_link
          url = 'https://docs.gitlab.com/runner/install/'

          case format
          when :html
            ActionController::Base.helpers.link_to cta2_text, url, target: '_blank', rel: 'noopener noreferrer'
          else
            [cta2_text, url].join(' >> ')
          end
        end

        def learn_more_link
          link(s_('AccountValidation|Learn more.'), 'https://about.gitlab.com/blog/2021/05/17/prevent-crypto-mining-abuse/')
        end

        def unsubscribe
          parts = [
            s_('AccountValidation|If you no longer wish to receive marketing emails from us,'),
            s_('AccountValidation|you may %{unsubscribe_link} at any time.') % { unsubscribe_link: mailgun_unsubscribe_link }
          ]

          case format
          when :html
            parts.join(' ')
          else
            parts.join("\n" + ' ' * 16)
          end
        end

        private

        def mailgun_unsubscribe_link
          mailgun_unsubscribe_url = '%tag_unsubscribe_url%'

          link(s_('AccountValidation|unsubscribe'), mailgun_unsubscribe_url)
        end
      end
    end
  end
end
