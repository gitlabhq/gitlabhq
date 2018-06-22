# frozen_string_literal: true

require 'support/helpers/markdown_feature'

module EE
  class MarkdownFeature < ::MarkdownFeature
    def epic
      @epic ||= create(:epic, title: 'epic', group: group)
    end

    def epic_other_group
      @epic ||= create(:epic, title: 'epic')
    end
  end
end
