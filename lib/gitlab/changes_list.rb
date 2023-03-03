# frozen_string_literal: true

module Gitlab
  class ChangesList
    include Enumerable

    attr_reader :raw_changes

    def initialize(changes)
      @raw_changes = changes.is_a?(String) ? changes.lines : changes
    end

    def each(&block)
      changes.each(&block)
    end

    def changes
      @changes ||= @raw_changes.filter_map do |change|
        next if change.blank?

        oldrev, newrev, ref = change.strip.split(' ')
        { oldrev: oldrev, newrev: newrev, ref: ref }
      end
    end
  end
end
