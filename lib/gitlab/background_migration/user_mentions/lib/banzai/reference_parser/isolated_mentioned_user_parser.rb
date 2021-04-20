# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    module UserMentions
      module Lib
        module Banzai
          module ReferenceParser
            # isolated Banzai::ReferenceParser::MentionedGroupParser
            class IsolatedMentionedUserParser < ::Banzai::ReferenceParser::MentionedUserParser
              extend ::Gitlab::Utils::Override

              self.reference_type = :user

              override :references_relation
              def references_relation
                ::Gitlab::BackgroundMigration::UserMentions::Models::User
              end
            end
          end
        end
      end
    end
  end
end
