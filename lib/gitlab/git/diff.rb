# Gitlab::Git::Diff is a wrapper around native Grit::Diff object
# We dont want to use grit objects inside app/
# It helps us easily migrate to rugged in future
module Gitlab
  module Git
    class Diff
      BROKEN_DIFF = "--broken-diff"

      attr_accessor :raw_diff

      # Diff properties
      attr_accessor :old_path, :new_path, :a_mode, :b_mode, :diff

      # Stats properties
      attr_accessor  :new_file, :renamed_file, :deleted_file

      def initialize(raw_diff, head = nil)
        raise "Nil as raw diff passed" unless raw_diff

        if raw_diff.is_a?(Hash)
          init_from_hash(raw_diff)
        else
          init_from_grit(raw_diff)
        end

        @head = head
      end

      def serialize_keys
        %w(diff new_path old_path a_mode b_mode new_file renamed_file deleted_file)
      end

      def to_hash
        hash = {}

        keys = serialize_keys

        keys.each do |key|
          hash[key] = send(key)
        end

        hash
      end

      private

      def init_from_grit(grit)
        @raw_diff = grit

        serialize_keys.each do |key|
          send(:"#{key}=", grit.send(key))
        end
      end

      def init_from_hash(hash)
        serialize_keys.each do |key|
          send(:"#{key}=", hash[key])
        end
      end
    end
  end
end

