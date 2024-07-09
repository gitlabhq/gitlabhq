# frozen_string_literal: true

module Gitlab
  module Page
    module Group
      module Settings
        module UsageQuotas
          # @note Defined as +link :storage_tab+
          # Clicks +storage_tab+
          def storage_tab
            # This is a stub, used for indexing. The method is dynamically generated.
          end

          # @example
          #   Gitlab::Page::Group::Settings::UsageQuotas.perform do |usage_quotas|
          #     expect(usage_quotas.storage_tab_element).to exist
          #   end
          # @return [Watir::Link] The raw +Link+ element
          def storage_tab_element
            # This is a stub, used for indexing. The method is dynamically generated.
          end

          # @example
          #   Gitlab::Page::Group::Settings::UsageQuotas.perform do |usage_quotas|
          #     expect(usage_quotas).to be_storage_tab
          #   end
          # @return [Boolean] true if the +storage_tab+ element is present on the page
          def storage_tab?
            # This is a stub, used for indexing. The method is dynamically generated.
          end

          # @note Defined as +span :group_usage_message+
          # @return [String] The text content or value of +group_usage_message+
          def group_usage_message
            # This is a stub, used for indexing. The method is dynamically generated.
          end

          # @example
          #   Gitlab::Page::Group::Settings::UsageQuotas.perform do |usage_quotas|
          #     expect(usage_quotas.group_usage_message_element).to exist
          #   end
          # @return [Watir::Span] The raw +Div+ element
          def group_usage_message_element
            # This is a stub, used for indexing. The method is dynamically generated.
          end

          # @example
          #   Gitlab::Page::Group::Settings::UsageQuotas.perform do |usage_quotas|
          #     expect(usage_quotas).to be_group_usage_message
          #   end
          # @return [Boolean] true if the +group_usage_message+ element is present on the page
          def group_usage_message?
            # This is a stub, used for indexing. The method is dynamically generated.
          end

          # @note Defined as +span :dependency_proxy_size+
          # @return [String] The text content or value of +dependency_proxy_size+
          def dependency_proxy_size
            # This is a stub, used for indexing. The method is dynamically generated.
          end

          # @example
          #   Gitlab::Page::Group::Settings::UsageQuotas.perform do |usage_quotas|
          #     expect(usage_quotas.dependency_proxy_size_element).to exist
          #   end
          # @return [Watir::Span] The raw +Span+ element
          def dependency_proxy_size_element
            # This is a stub, used for indexing. The method is dynamically generated.
          end

          # @example
          #   Gitlab::Page::Group::Settings::UsageQuotas.perform do |usage_quotas|
          #     expect(usage_quotas).to be_dependency_proxy_size
          #   end
          # @return [Boolean] true if the +dependency_proxy_size+ element is present on the page
          def dependency_proxy_size?
            # This is a stub, used for indexing. The method is dynamically generated.
          end
        end
      end
    end
  end
end
