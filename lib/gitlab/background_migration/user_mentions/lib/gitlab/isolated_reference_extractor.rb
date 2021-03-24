# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    module UserMentions
      module Lib
        module Gitlab
          # Extract possible GFM references from an arbitrary String for further processing.
          class IsolatedReferenceExtractor < ::Gitlab::ReferenceExtractor
            REFERABLES = %i(isolated_mentioned_group isolated_mentioned_user isolated_mentioned_project).freeze

            REFERABLES.each do |type|
              define_method("#{type}s") do
                @references[type] ||= isolated_references(type)
              end
            end

            def isolated_references(type)
              context = ::Banzai::RenderContext.new(project, current_user)
              processor = ::Gitlab::BackgroundMigration::UserMentions::Lib::Banzai::ReferenceParser[type].new(context)

              refs = processor.process(html_documents)
              refs[:visible]
            end
          end
        end
      end
    end
  end
end
