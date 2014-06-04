# This is a patch to address the issue in https://github.com/mbleigh/acts-as-taggable-on/issues/427 caused by
# https://github.com/rails/rails/commit/31a43ebc107fbd50e7e62567e5208a05909ec76c
# gem 'acts-as-taggable-on' has the fix included https://github.com/mbleigh/acts-as-taggable-on/commit/89bbed3864a9252276fb8dd7d535fce280454b90
# but not in the currently used version of gem ('2.4.1')
# With replacement of 'acts-as-taggable-on' gem this file will become obsolete

module ActsAsTaggableOn::Taggable
  module Core
    module ClassMethods
      def tagged_with(tags, options = {})
        tag_list = ActsAsTaggableOn::TagList.from(tags)
        empty_result = where("1 = 0")

        return empty_result if tag_list.empty?

        joins = []
        conditions = []
        having = []
        select_clause = []

        context = options.delete(:on)
        owned_by = options.delete(:owned_by)
        alias_base_name = undecorated_table_name.gsub('.','_')
        quote = ActsAsTaggableOn::Tag.using_postgresql? ? '"' : ''

        if options.delete(:exclude)
          if options.delete(:wild)
            tags_conditions = tag_list.map { |t| sanitize_sql(["#{ActsAsTaggableOn::Tag.table_name}.name #{like_operator} ? ESCAPE '!'", "%#{escape_like(t)}%"]) }.join(" OR ")
          else
            tags_conditions = tag_list.map { |t| sanitize_sql(["#{ActsAsTaggableOn::Tag.table_name}.name #{like_operator} ?", t]) }.join(" OR ")
          end

          conditions << "#{table_name}.#{primary_key} NOT IN (SELECT #{ActsAsTaggableOn::Tagging.table_name}.taggable_id FROM #{ActsAsTaggableOn::Tagging.table_name} JOIN #{ActsAsTaggableOn::Tag.table_name} ON #{ActsAsTaggableOn::Tagging.table_name}.tag_id = #{ActsAsTaggableOn::Tag.table_name}.#{ActsAsTaggableOn::Tag.primary_key} AND (#{tags_conditions}) WHERE #{ActsAsTaggableOn::Tagging.table_name}.taggable_type = #{quote_value(base_class.name, nil)})"

          if owned_by
            joins <<  "JOIN #{ActsAsTaggableOn::Tagging.table_name}" +
                      "  ON #{ActsAsTaggableOn::Tagging.table_name}.taggable_id = #{quote}#{table_name}#{quote}.#{primary_key}" +
                      " AND #{ActsAsTaggableOn::Tagging.table_name}.taggable_type = #{quote_value(base_class.name, nil)}" +
                      " AND #{ActsAsTaggableOn::Tagging.table_name}.tagger_id = #{owned_by.id}" +
                      " AND #{ActsAsTaggableOn::Tagging.table_name}.tagger_type = #{quote_value(owned_by.class.base_class.to_s, nil)}"
          end

        elsif options.delete(:any)
          # get tags, drop out if nothing returned (we need at least one)
          tags = if options.delete(:wild)
            ActsAsTaggableOn::Tag.named_like_any(tag_list)
          else
            ActsAsTaggableOn::Tag.named_any(tag_list)
          end

          return empty_result unless tags.length > 0

          # setup taggings alias so we can chain, ex: items_locations_taggings_awesome_cool_123
          # avoid ambiguous column name
          taggings_context = context ? "_#{context}" : ''

          taggings_alias   = adjust_taggings_alias(
            "#{alias_base_name[0..4]}#{taggings_context[0..6]}_taggings_#{sha_prefix(tags.map(&:name).join('_'))}"
          )

          tagging_join  = "JOIN #{ActsAsTaggableOn::Tagging.table_name} #{taggings_alias}" +
                          "  ON #{taggings_alias}.taggable_id = #{quote}#{table_name}#{quote}.#{primary_key}" +
                          " AND #{taggings_alias}.taggable_type = #{quote_value(base_class.name, nil)}"
          tagging_join << " AND " + sanitize_sql(["#{taggings_alias}.context = ?", context.to_s]) if context

          # don't need to sanitize sql, map all ids and join with OR logic
          conditions << tags.map { |t| "#{taggings_alias}.tag_id = #{t.id}" }.join(" OR ")
          select_clause = "DISTINCT #{table_name}.*" unless context and tag_types.one?

          if owned_by
              tagging_join << " AND " +
                  sanitize_sql([
                      "#{taggings_alias}.tagger_id = ? AND #{taggings_alias}.tagger_type = ?",
                      owned_by.id,
                      owned_by.class.base_class.to_s
                  ])
          end

          joins << tagging_join
        else
          tags = ActsAsTaggableOn::Tag.named_any(tag_list)

          return empty_result unless tags.length == tag_list.length

          tags.each do |tag|
            taggings_alias = adjust_taggings_alias("#{alias_base_name[0..11]}_taggings_#{sha_prefix(tag.name)}")
            tagging_join  = "JOIN #{ActsAsTaggableOn::Tagging.table_name} #{taggings_alias}" +
                            "  ON #{taggings_alias}.taggable_id = #{quote}#{table_name}#{quote}.#{primary_key}" +
                            " AND #{taggings_alias}.taggable_type = #{quote_value(base_class.name, nil)}" +
                            " AND #{taggings_alias}.tag_id = #{tag.id}"

            tagging_join << " AND " + sanitize_sql(["#{taggings_alias}.context = ?", context.to_s]) if context

            if owned_by
                tagging_join << " AND " +
                  sanitize_sql([
                    "#{taggings_alias}.tagger_id = ? AND #{taggings_alias}.tagger_type = ?",
                    owned_by.id,
                    owned_by.class.base_class.to_s
                  ])
            end

            joins << tagging_join
          end
        end

        taggings_alias, tags_alias = adjust_taggings_alias("#{alias_base_name}_taggings_group"), "#{alias_base_name}_tags_group"

        if options.delete(:match_all)
          joins << "LEFT OUTER JOIN #{ActsAsTaggableOn::Tagging.table_name} #{taggings_alias}" +
                   "  ON #{taggings_alias}.taggable_id = #{quote}#{table_name}#{quote}.#{primary_key}" +
                   " AND #{taggings_alias}.taggable_type = #{quote_value(base_class.name, nil)}"


          group_columns = ActsAsTaggableOn::Tag.using_postgresql? ? grouped_column_names_for(self) : "#{table_name}.#{primary_key}"
          group = group_columns
          having = "COUNT(#{taggings_alias}.taggable_id) = #{tags.size}"
        end

        select(select_clause) \
          .joins(joins.join(" ")) \
          .where(conditions.join(" AND ")) \
          .group(group) \
          .having(having) \
          .order(options[:order]) \
          .readonly(false)
      end
    end
  end
end
