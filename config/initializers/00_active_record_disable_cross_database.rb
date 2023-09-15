# frozen_string_literal: true

module ActiveRecordBaseCrossDatabaseIgnoreFactoryBot
  def ignore_cross_database_tables_if_factory_bot(...)
    # this method is implemented in:
    # spec/support/database/prevent_cross_database_modification.rb
    yield
  end
end

ActiveRecord::Base.prepend(ActiveRecordBaseCrossDatabaseIgnoreFactoryBot)
