# frozen_string_literal: true

module SshKeys
  class ExpiredNotificationWorker
    include ApplicationWorker

    sidekiq_options retry: 3
    include CronjobQueue

    feature_category :compliance_management
    tags :exclude_from_kubernetes
    idempotent!

    BATCH_SIZE = 500

    # rubocop: disable CodeReuse/ActiveRecord
    def perform
      order = Gitlab::Pagination::Keyset::Order.build([
        Gitlab::Pagination::Keyset::ColumnOrderDefinition.new(
          attribute_name: 'expires_at_utc',
          order_expression: Arel.sql("date(expires_at AT TIME ZONE 'UTC')").asc,
          nullable: :not_nullable,
          distinct: false,
          add_to_projections: true
        ),
        Gitlab::Pagination::Keyset::ColumnOrderDefinition.new(
          attribute_name: 'id',
          order_expression: Key.arel_table[:id].asc
        )
      ])

      scope = Key.expired_and_not_notified.order(order)

      iterator = Gitlab::Pagination::Keyset::Iterator.new(scope: scope, use_union_optimization: true)
      iterator.each_batch(of: BATCH_SIZE) do |relation|
        users = User.where(id: relation.map(&:user_id)) # Keyset pagination will load the rows

        users.each do |user|
          with_context(user: user) do
            Keys::ExpiryNotificationService.new(user, { keys: user.expired_and_unnotified_keys, expiring_soon: false }).execute
          end
        end
      end
    end
    # rubocop: enable CodeReuse/ActiveRecord
  end
end
