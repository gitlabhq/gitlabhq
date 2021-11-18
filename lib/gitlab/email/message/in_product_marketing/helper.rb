# frozen_string_literal: true

module Gitlab
  module Email
    module Message
      module InProductMarketing
        module Helper
          include ActionView::Context
          include ActionView::Helpers::TagHelper

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
