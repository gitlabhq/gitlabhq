# frozen_string_literal: true

module Members
  module Enumerable
    extend ActiveSupport::Concern

    include EachBatch

    included do
      def each_member_user(filters = {}, &block)
        each_member_user_batch(filters) { |users| users.each(&block) }
      end

      def map_member_user(filters = {}, &block)
        values = []

        each_member_user_batch(filters) { |users| values.concat(users.map(&block)) }

        values
      end

      def pluck_member_user(*columns, filters: {})
        values = []

        # rubocop:disable Database/AvoidUsingPluckWithoutLimit -- plucking on batch
        each_member_user_batch(filters) { |users| values.concat(users.pluck(*columns)) }
        # rubocop:enable Database/AvoidUsingPluckWithoutLimit

        values
      end

      private

      def each_member_user_batch(filters = {})
        members.non_request.non_invite.where(filters).each_batch do |relation|
          yield User.id_in(relation.pluck_user_ids)
        end
      end
    end
  end
end
