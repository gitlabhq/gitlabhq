# frozen_string_literal: true

module Gitlab
  module Database
    class LockRecorder
      def self.instance
        Thread.current[:lock_recorder] ||= new
      end

      def self.record_key(record)
        [record.class.table_name, record.id]
      end

      def locks
        @locks ||= {}
      end

      def add(record, lock_type)
        key = LockRecorder.record_key(record)

        locks[key] = lock_type
      end

      def recording
        @recording = false unless defined?(@recording)
        @recording
      end

      def start
        @recording = true
      end

      def stop
        @recording = false
      end

      def recording?
        recording
      end

      def clear
        locks.clear
      end
    end
  end
end
