# frozen_string_literal: true

ActiveRecord::ConnectionAdapters::ConnectionPool.prepend Gitlab::Patch::ActiveRecordQueryCache
