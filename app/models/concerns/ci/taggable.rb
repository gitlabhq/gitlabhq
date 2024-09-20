# frozen_string_literal: true

module Ci
  module Taggable
    extend ActiveSupport::Concern
    include Gitlab::Utils::StrongMemoize

    included do
      after_save :save_tags

      # rubocop:disable Cop/ActiveRecordDependent -- existing
      has_many :tag_taggings, -> { includes(:tag).where(context: :tags) }, # rubocop:disable Rails/InverseOf -- existing
        as: :taggable,
        class_name: 'Ci::Tagging',
        dependent: :destroy,
        after_add: :dirtify_tag_list,
        after_remove: :dirtify_tag_list

      has_many :tags,
        class_name: 'Ci::Tag',
        through: :tag_taggings,
        source: :tag,
        after_add: :dirtify_tag_list,
        after_remove: :dirtify_tag_list

      has_many :taggings, as: :taggable, dependent: :destroy, class_name: '::Ci::Tagging'
      has_many :base_tags, through: :taggings, source: :tag, class_name: '::Ci::Tag'
      # rubocop:enable Cop/ActiveRecordDependent -- existing

      attribute :tag_list, Gitlab::Database::Type::TagListType.new

      scope :tagged_with, ->(tags) do
        Gitlab::Ci::Tags::Parser
          .new(tags)
          .parse
          .map { |tag| with_tag(tag) }
          .reduce(:and)
      end

      scope :with_tag, ->(name) do
        where_exists(
          Tagging
            .merge(unscoped.scoped_tagging)
            .where(context: :tags)
            .where(tag_id: Tag.where(name: name))
        )
      end

      scope :scoped_tagging, -> do
        where(arel_table[primary_key].eq(Tagging.arel_table[:taggable_id]))
          .where(Tagging.arel_table[:taggable_type].eq(base_class.name))
      end
    end

    def tag_list
      Gitlab::Ci::Tags::TagList.new(context_tags.map(&:name))
    end
    strong_memoize_attr :tag_list

    def tag_list=(new_tags)
      parsed_new_list = Gitlab::Ci::Tags::Parser.new(new_tags).parse
      write_attribute('tag_list', parsed_new_list)
      instance_variable_set(:@tag_list, parsed_new_list)
    end

    def reload(*args)
      clear_memoization(:tag_list)
      super(*args)
    end

    private

    def dirtify_tag_list(_tag)
      attribute_will_change!(:tag_list)
      clear_memoization(:tag_list)
    end

    def context_tags
      base_tags.where(taggings: { context: :tags, tagger_id: nil })
    end

    def tag_list_cache_set?
      strong_memoized?(:tag_list)
    end

    def save_tags
      return unless tag_list_cache_set?

      tags = find_or_create_tags_from_list(tag_list.uniq)
      current_tags = context_tags
      old_tags = current_tags - tags
      new_tags = tags - current_tags

      taggings.by_context(:tags).where(tag_id: old_tags).delete_all if old_tags.present?

      new_tags.each do |tag|
        taggings.create!(tag_id: tag.id, context: 'tags', taggable: self)
      end

      yield(new_tags, old_tags) if block_given?

      true
    end

    def find_or_create_tags_from_list(tags)
      Ci::Tag.find_or_create_all_with_like_by_name(tags)
    end
  end
end
