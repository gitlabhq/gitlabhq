# frozen_string_literal: true

module PopulatesShardingKey # rubocop:disable Gitlab/BoundedContexts -- general purpose concern for ApplicationRecord
  extend ActiveSupport::Concern

  class_methods do
    # Simple DSL to isolate sharding key population in models
    # Examples:
    # populate_sharding_key :project_id, source: :issue
    # populate_sharding_key :project_id, source: :merge_request, field: :target_project_id
    # populate_sharding_key :project_id do
    #   issue.project_id
    # end
    # populate_sharding_key :project_id, &:get_sharding_key
    # Also see `populate_sharding_key` spec matcher
    def populate_sharding_key(sharding_attribute, source: nil, field: sharding_attribute, &block)
      value_proc = block || proc { send(source)&.public_send(field) } # rubocop:disable GitlabSecurity/PublicSend -- send is intended

      before_validation -> { assign_attributes(sharding_attribute => instance_exec(self, &value_proc)) },
        unless: :"#{sharding_attribute}?"
    end
  end
end
