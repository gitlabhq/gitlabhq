# frozen_string_literal: true

module WorkItems
  module DataSync
    module Widgets
      class AwardEmoji < Base
        def after_create
          return unless params[:operation] == :move
          return unless target_work_item.get_widget(:award_emoji)

          work_item.award_emoji.each_batch(of: BATCH_SIZE) do |awards_batch|
            ::AwardEmoji.insert_all(new_work_item_award_emoji(awards_batch))
          end
        end

        def post_move_cleanup
          work_item.award_emoji.each_batch(of: BATCH_SIZE) do |award_emoji_batch|
            ::AwardEmoji.id_in(award_emoji_batch.select(:id)).delete_all
          end
        end

        private

        def new_work_item_award_emoji(awards_batch)
          awards_batch.map do |award|
            award.attributes.except("id").tap do |attr|
              attr['awardable_id'] = target_work_item.id
              # we want to explicitly set this because for legacy Epic we can have some emoji linked to the
              # Epic Work Item(i.e. target_type=Issue) and some to the legacy Epic(i.e target_type=Epic)
              attr['awardable_type'] = target_work_item.class.base_class.name
            end
          end
        end
      end
    end
  end
end
