# frozen_string_literal: true

module API
  module Entities
    module Users
      module BioHtml
        extend ActiveSupport::Concern

        included do
          expose :bio_html, documentation: { type: 'String', example: 'My <em>bio</em>.' } do |user|
            MarkupHelper.markdown_field(user.user_detail, :bio) if user.user_detail
          end
        end
      end
    end
  end
end
