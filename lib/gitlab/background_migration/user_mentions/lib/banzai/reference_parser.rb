# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    module UserMentions
      module Lib
        module Banzai
          # isolated Banzai::ReferenceParser
          module ReferenceParser
            # Returns the reference parser class for the given type
            #
            # Example:
            #
            #     Banzai::ReferenceParser['isolated_mentioned_group']
            #
            # This would return the `::Gitlab::BackgroundMigration::UserMentions::Lib::Banzai::ReferenceParser::IsolatedMentionedGroupParser` class.
            def self.[](name)
              const_get("::Gitlab::BackgroundMigration::UserMentions::Lib::Banzai::ReferenceParser::#{name.to_s.camelize}Parser", false)
            end
          end
        end
      end
    end
  end
end
