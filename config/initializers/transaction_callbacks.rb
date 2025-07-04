# frozen_string_literal: true

# Extends ActiveRecord transactions with the ability of
# registering callbacks to run after the transaction completes.
#
# This feature is already implemented in Rails 7.2.0 but we are still using
# the version 7.1.x. This means that we can remove this patch while upgrading
# Rails version to 7.2.x.
#
# ApplicationRecord.transaction do
#   ApplicationRecord.current_transaction.after_commit do
#     SomeSidekiqJob.perform_later
#   end
#
#   Project.touch
# end

if ActiveRecord::ConnectionAdapters::NullTransaction.new.respond_to?(:before_commit)
  raise 'This version of Rails natively supports transaction callbacks. Please remove this patch.'
end

ActiveRecord::ConnectionAdapters::NullTransaction.prepend(
  GemExtensions::ActiveRecord::ConnectionAdapters::Transaction::NullTransactionCallbacks)

ActiveRecord::ConnectionAdapters::Transaction.prepend(
  GemExtensions::ActiveRecord::ConnectionAdapters::Transaction::TransactionCallbacks)
