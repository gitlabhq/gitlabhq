# frozen_string_literal: true

# Convert any ActiveRecord::Relation to a Gitlab::SQL::CTE
module AsCte
  extend ActiveSupport::Concern

  class_methods do
    def as_cte(name, **opts)
      Gitlab::SQL::CTE.new(name, all, **opts)
    end
  end
end
