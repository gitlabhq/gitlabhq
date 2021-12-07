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

          private

          def list(array)
            case format
            when :html
              tag.ul { array.map { |item| tag.li item} }
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
