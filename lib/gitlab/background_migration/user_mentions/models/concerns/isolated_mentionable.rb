# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    module UserMentions
      module Models
        module Concerns
          # == IsolatedMentionable concern
          #
          # Shortcutted for isolation version of Mentionable to be used in mentions migrations
          #
          module IsolatedMentionable
            extend ::ActiveSupport::Concern

            class_methods do
              # Indicate which attributes of the Mentionable to search for GFM references.
              def attr_mentionable(attr, options = {})
                attr = attr.to_s
                mentionable_attrs << [attr, options]
              end
            end

            included do
              # Accessor for attributes marked mentionable.
              cattr_accessor :mentionable_attrs, instance_accessor: false do
                []
              end

              if self < Participable
                participant -> (user, ext) { all_references(user, extractor: ext) }
              end
            end

            def all_references(current_user = nil, extractor: nil)
              # Use custom extractor if it's passed in the function parameters.
              if extractor
                extractors[current_user] = extractor
              else
                extractor = extractors[current_user] ||=
                  Gitlab::BackgroundMigration::UserMentions::Lib::Gitlab::IsolatedReferenceExtractor.new(project, current_user)

                extractor.reset_memoized_values
              end

              self.class.mentionable_attrs.each do |attr, options|
                text    = __send__(attr) # rubocop:disable GitlabSecurity/PublicSend
                options = options.merge(
                  cache_key: [self, attr],
                  author: author,
                  skip_project_check: skip_project_check?
                ).merge(mentionable_params)

                cached_html = self.try(:updated_cached_html_for, attr.to_sym)
                options[:rendered] = cached_html if cached_html

                extractor.analyze(text, options)
              end

              extractor
            end

            def extractors
              @extractors ||= {}
            end

            def skip_project_check?
              false
            end

            def build_mention_values(resource_foreign_key)
              refs = all_references(author)

              mentioned_users_ids = array_to_sql(refs.isolated_mentioned_users.pluck(:id))
              mentioned_projects_ids = array_to_sql(refs.isolated_mentioned_projects.pluck(:id))
              mentioned_groups_ids = array_to_sql(refs.isolated_mentioned_groups.pluck(:id))

              return if mentioned_users_ids.blank? && mentioned_projects_ids.blank? && mentioned_groups_ids.blank?

              {
                "#{resource_foreign_key}": user_mention_resource_id,
                note_id: user_mention_note_id,
                mentioned_users_ids: mentioned_users_ids,
                mentioned_projects_ids: mentioned_projects_ids,
                mentioned_groups_ids: mentioned_groups_ids
              }
            end

            def array_to_sql(ids_array)
              return unless ids_array.present?

              '{' + ids_array.join(", ") + '}'
            end

            private

            def mentionable_params
              {}
            end
          end
        end
      end
    end
  end
end
