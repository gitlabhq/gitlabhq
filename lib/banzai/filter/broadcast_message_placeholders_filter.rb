# frozen_string_literal: true

module Banzai
  module Filter
    # Replaces placeholders for broadcast messages with data from the current
    # user or the instance.
    class BroadcastMessagePlaceholdersFilter < HTML::Pipeline::Filter
      prepend Concerns::PipelineTimingCheck

      def call
        return doc unless context[:broadcast_message_placeholders]

        doc.traverse { |node| replace_placeholders(node) }
      end

      private

      def replace_placeholders(node)
        if node.text? && !node.content.empty?
          node.content = replace_content(node.content)
        elsif href = link_href(node)
          href.value = replace_content(href.value, url_safe_encoding: true)
        end

        node
      end

      def link_href(node)
        node.element? &&
          node.name == 'a' &&
          node.attribute_nodes.find { |a| a.name == "href" }
      end

      def replace_content(content, url_safe_encoding: false)
        placeholders.each do |placeholder, method|
          regex = Regexp.new("{{#{placeholder}}}|#{CGI.escape("{{#{placeholder}}}")}")
          value = url_safe_encoding ? CGI.escape(method.call.to_s) : method.call.to_s
          content.gsub!(regex, value)
        end

        content
      end

      def placeholders
        {
          "email" => -> { current_user.try(:email) },
          "name" => -> { current_user.try(:name) },
          "user_id" => -> { current_user.try(:id) },
          "username" => -> { current_user.try(:username) },
          "instance_id" => -> { Gitlab::CurrentSettings.try(:uuid) }
        }
      end

      def current_user
        context[:current_user]
      end
    end
  end
end
