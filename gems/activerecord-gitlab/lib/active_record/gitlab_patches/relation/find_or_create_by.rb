# frozen_string_literal: true

module ActiveRecord
  module GitlabPatches
    module Relation
      module FindOrCreateBy
        # Adds patch for ActiveRecord `find_or_create_by`/`find_or_create_by!` methods
        # so as to prevent it from opening subtransactions.

        # Rails commit: https://github.com/rails/rails/commit/023a3eb3c046091a5d52027393a6d29d0576da01
        # Issue: https://gitlab.com/gitlab-org/gitlab/-/issues/439567
        def find_or_create_by(attributes, &block)
          find_by(attributes) || create(attributes, &block)
        end

        def find_or_create_by!(attributes, &block)
          find_by(attributes) || create!(attributes, &block)
        end
      end
    end
  end
end

ActiveSupport.on_load(:active_record) do
  ActiveRecord::Relation.prepend(ActiveRecord::GitlabPatches::Relation::FindOrCreateBy)
end
