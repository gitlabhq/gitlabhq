# frozen_string_literal: true

module Gitlab
  module Email
    module Message
      module InProductMarketing
        module Helper
          include ActionView::Context
          include ActionView::Helpers::TagHelper

          def footer_links
            links = [
              [s_('InProductMarketing|Blog'), 'https://about.gitlab.com/blog'],
              [s_('InProductMarketing|Twitter'), 'https://twitter.com/gitlab'],
              [s_('InProductMarketing|Facebook'), 'https://www.facebook.com/gitlab'],
              [s_('InProductMarketing|YouTube'), 'https://www.youtube.com/channel/UCnMGQ8QHMAnVIsI3xJrihhg']
            ]
            case format
            when :html
              links.map do |text, link|
                ActionController::Base.helpers.link_to(text, link)
              end
            else
              '| ' + links.map do |text, link|
                [text, link].join(' ')
              end.join("\n| ")
            end
          end

          def address
            s_('InProductMarketing|%{strong_start}GitLab Inc.%{strong_end} 268 Bush Street, #350, San Francisco, CA 94104, USA').html_safe % strong_options
          end

          def unsubscribe_message(self_managed_preferences_link = nil)
            parts = Gitlab.com? ? unsubscribe_com : unsubscribe_self_managed(self_managed_preferences_link)

            case format
            when :html
              parts.join(' ')
            else
              parts.join("\n" + ' ' * 16)
            end
          end

          private

          def unsubscribe_link
            unsubscribe_url = Gitlab.com? ? '%tag_unsubscribe_url%' : profile_notifications_url

            link(s_('InProductMarketing|unsubscribe'), unsubscribe_url)
          end

          def unsubscribe_com
            [
              s_('InProductMarketing|If you no longer wish to receive marketing emails from us,'),
              s_('InProductMarketing|you may %{unsubscribe_link} at any time.') % { unsubscribe_link: unsubscribe_link }
            ]
          end

          def unsubscribe_self_managed(preferences_link)
            [
              s_('InProductMarketing|To opt out of these onboarding emails, %{unsubscribe_link}.') % { unsubscribe_link: unsubscribe_link },
              s_("InProductMarketing|If you don't want to receive marketing emails directly from GitLab, %{marketing_preference_link}.") % { marketing_preference_link: preferences_link }
            ]
          end

          def list(array)
            case format
            when :html
              tag.ul { array.map { |item| tag.li item } }
            else
              '- ' + array.join("\n- ")
            end
          end

          def strong_options
            case format
            when :html
              { strong_start: '<b>'.html_safe, strong_end: '</b>'.html_safe }
            else
              { strong_start: '', strong_end: '' }
            end
          end

          def link(text, link)
            case format
            when :html
              ActionController::Base.helpers.link_to text, link
            else
              "#{text} (#{link})"
            end
          end

          def action_link(text, link)
            case format
            when :html
              ActionController::Base.helpers.link_to text, link, target: '_blank', rel: 'noopener noreferrer'
            else
              [text, link].join(' >> ')
            end
          end
        end
      end
    end
  end
end
