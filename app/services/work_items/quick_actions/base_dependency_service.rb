# frozen_string_literal: true

module WorkItems
  module QuickActions
    class BaseDependencyService
      def initialize(target, user, project, group = nil)
        @target = target
        @user = user
        @project = project
        @group = group
      end

      def format_refs(items)
        items.map { |item| format_ref(item) }.to_sentence
      end

      def format_ref(item)
        item.to_reference(@target.project || @target.namespace)
      end

      private

      def build_extractor(items)
        ext = ::Gitlab::ReferenceExtractor.new(@project, @user)
        ext.analyze(items, author: @user, group: @group)
        ext
      end
    end
  end
end
