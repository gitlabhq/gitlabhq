# frozen_string_literal: true

if Rails.gem_version >= Gem::Version.new('7.2')
  raise 'Given that we are relying on a few Rails internal in ' \
    '`app/models/cells/transaction_record.rb`, we should verify if ' \
    'the contract still holds. If it does, please bump the version here.'
end

ActiveRecord::ConnectionAdapters::Transaction.prepend(Cells::TransactionRecord::TransactionExtension)
