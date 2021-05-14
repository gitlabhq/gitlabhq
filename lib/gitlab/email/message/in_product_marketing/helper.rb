# frozen_string_literal: true

module Gitlab
  module Email
    module Message
      module InProductMarketing
        module Helper
          include ActionView::Context
          include ActionView::Helpers::TagHelper
          include ActionView::Helpers::UrlHelper

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
              link_to text, link
            else
              "#{text} (#{link})"
            end
          end
        end
      end
    end
  end
end
