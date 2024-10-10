# frozen_string_literal: true

module BaseLabel # rubocop:disable Gitlab/BoundedContexts -- existing Label modules/classes are not bounded
  extend ActiveSupport::Concern

  DEFAULT_COLOR = ::Gitlab::Color.of('#6699cc')

  included do
    include CacheMarkdownField
    include Gitlab::SQL::Pattern

    cache_markdown_field :description, pipeline: :single_line

    attribute :color, ::Gitlab::Database::Type::Color.new, default: DEFAULT_COLOR

    before_validation :strip_whitespace_from_title

    validates :color, color: true, presence: true

    # Don't allow ',' for label titles
    validates :title, presence: true, format: { with: /\A[^,]+\z/ }
    validates :title, length: { maximum: 255 }

    # Searches for labels with a matching title or description.
    #
    # This method uses ILIKE on PostgreSQL.
    #
    # query - The search query as a String.
    #
    # Returns an ActiveRecord::Relation.
    def self.search(query, **options)
      # make sure we prevent passing in disallowed columns
      search_in = case options[:search_in]
                  when [:title]
                    [:title]
                  when [:description]
                    [:description]
                  else
                    [:title, :description]
                  end

      fuzzy_search(query, search_in)
    end

    # Override Gitlab::SQL::Pattern.min_chars_for_partial_matching as
    # label queries are never global, and so will not use a trigram
    # index. That means we can have just one character in the LIKE.
    def self.min_chars_for_partial_matching
      1
    end

    def color
      super || DEFAULT_COLOR
    end

    def text_color
      color.contrast
    end

    def title=(value)
      if value.blank?
        super
      else
        write_attribute(:title, sanitize_value(value))
      end
    end

    def description=(value)
      if value.blank?
        super
      else
        write_attribute(:description, sanitize_value(value))
      end
    end

    private

    def sanitize_value(value)
      CGI.unescapeHTML(Sanitize.clean(value.to_s))
    end

    def strip_whitespace_from_title
      self[:title] = title&.strip
    end
  end
end
