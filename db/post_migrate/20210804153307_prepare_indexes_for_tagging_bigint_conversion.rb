# frozen_string_literal: true

class PrepareIndexesForTaggingBigintConversion < ActiveRecord::Migration[6.1]
  include Gitlab::Database::MigrationHelpers

  def up
    prepare_async_index :taggings, :id_convert_to_bigint, unique: true,
      name: :index_taggings_on_id_convert_to_bigint

    prepare_async_index :taggings, [:taggable_id_convert_to_bigint, :taggable_type],
      name: :i_taggings_on_taggable_id_convert_to_bigint_and_taggable_type

    prepare_async_index :taggings, [:taggable_id_convert_to_bigint, :taggable_type, :context],
      name: :i_taggings_on_taggable_bigint_and_taggable_type_and_context

    prepare_async_index :taggings, [:tag_id, :taggable_id_convert_to_bigint, :taggable_type, :context, :tagger_id, :tagger_type],
      unique: true, name: :taggings_idx_tmp
  end

  def down
    unprepare_async_index_by_name :taggings, :taggings_idx_tmp

    unprepare_async_index_by_name :taggings, :i_taggings_on_taggable_bigint_and_taggable_type_and_context

    unprepare_async_index_by_name :taggings, :i_taggings_on_taggable_id_convert_to_bigint_and_taggable_type

    unprepare_async_index_by_name :taggings, :index_taggings_on_id_convert_to_bigint
  end
end
