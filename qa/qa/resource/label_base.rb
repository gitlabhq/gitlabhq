# frozen_string_literal: true

module QA
  module Resource
    # Base label class for GroupLabel and ProjectLabel
    #
    class LabelBase < Base
      attr_accessor :title, :description, :color

      attribute :id
      attribute :description_html
      attribute :text_color
      attribute :subscribed

      def initialize
        @title = "qa-test-#{SecureRandom.hex(8)}"
        @description = 'This is a test label'
        @color = '#0033CC'
      end

      def fabricate!
        Page::Label::Index.perform(&:click_new_label_button)
        Page::Label::New.perform do |new_page|
          new_page.fill_title(title)
          new_page.fill_description(description)
          new_page.fill_color(color)
          new_page.click_label_create_button
        end
      end

      # Resource web url
      #
      # @param [Hash] resource
      # @return [String]
      def resource_web_url(resource)
        super
      rescue ResourceURLMissingError
        # this particular resource does not expose a web_url property
      end

      # Params for label creation
      #
      # @return [Hash]
      def api_post_body
        {
          name: title,
          color: color,
          description: description
        }
      end

      protected

      # Return subset of fields for comparing labels
      #
      # @return [Hash]
      def comparable
        reload! unless api_response

        api_response.slice(
          :name,
          :description,
          :description_html,
          :color,
          :text_color,
          :subscribed
        )
      end
    end
  end
end
