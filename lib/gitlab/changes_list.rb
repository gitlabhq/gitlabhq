module Gitlab
  class ChangesList
    include Enumerable

    attr_reader :raw_changes

    def initialize(changes)
      @raw_changes = changes.kind_of?(String) ? changes.lines : changes
    end

    def each(&block)
      changes.each(&block)
    end

    def changes
      @changes ||= begin
        @raw_changes.map do |change|
          next if change.blank?
          oldrev, newrev, ref = change.strip.split(' ')
          { oldrev: oldrev, newrev: newrev, ref: ref }
        end.compact
      end
    end
  end
end
