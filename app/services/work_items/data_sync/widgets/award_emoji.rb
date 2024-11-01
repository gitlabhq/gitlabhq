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
            award_emoji_batch.delete_all
          end
        end

        private

        def new_work_item_award_emoji(awards_batch)
          awards_batch.map do |award|
            new_award = award.attributes

            new_award.delete("id")
            new_award['awardable_id'] = target_work_item.id

            new_award
          end
        end
      end
    end
  end
end
