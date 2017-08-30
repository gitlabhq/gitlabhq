module Gitlab
  module I18n
    class PoEntry
      def self.build(entry_data)
        if entry_data[:msgid].empty?
          MetadataEntry.new(entry_data)
        else
          TranslationEntry.new(entry_data)
        end
      end

      attr_reader :entry_data

      def initialize(entry_data)
        @entry_data = entry_data
      end
    end
  end
end
