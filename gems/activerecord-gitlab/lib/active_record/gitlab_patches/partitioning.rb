# frozen_string_literal: true

require_relative "partitioning/associations/builder/association"
require_relative "partitioning/reflection/abstract_reflection"
require_relative "partitioning/reflection/association_reflection"
require_relative "partitioning/reflection/macro_reflection"
require_relative "partitioning/base"

module ActiveRecord
  module GitlabPatches
    # This allows to filter data by a dedicated column for association and joins to ActiveRecord::Base.
    #
    # class ApplicationRecord < ActiveRecord::Base
    #   belongs_to :pipeline,
    #     -> (build) { where(partition_id: build.partition_id) },
    #     partition_foreign_key: :partition_id
    #
    # end
    module Partitioning
      ActiveSupport.on_load(:active_record) do
        ::ActiveRecord::Associations::Builder::Association.prepend(
          ActiveRecord::GitlabPatches::Partitioning::Associations::Builder::Association
        )
        ::ActiveRecord::Reflection::AbstractReflection.prepend(
          ActiveRecord::GitlabPatches::Partitioning::Reflection::AbstractReflection
        )
        ::ActiveRecord::Reflection::AssociationReflection.prepend(
          ActiveRecord::GitlabPatches::Partitioning::Reflection::AssociationReflection
        )
        ::ActiveRecord::Reflection::MacroReflection.prepend(
          ActiveRecord::GitlabPatches::Partitioning::Reflection::MacroReflection
        )
        ::ActiveRecord::Persistence.prepend(
          ActiveRecord::GitlabPatches::Partitioning::Base
        )
        ::ActiveRecord::Persistence::ClassMethods.prepend(
          ActiveRecord::GitlabPatches::Partitioning::Base::ClassMethods
        )
      end
    end
  end
end
