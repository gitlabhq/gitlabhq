# frozen_string_literal: true

module Banzai
  module Filter
    module Concerns
      # Provides convenience accessors for commonly-used values from `context`,
      # so filters don't each have to define their own `context[:project]` etc.
      # readers.
      module ContextAccessors
        extend ActiveSupport::Concern

        def project
          context[:project]
        end

        def current_user
          context[:current_user]
        end

        def group
          context[:group]
        end

        def author
          context[:author]
        end

        def user
          context[:user]
        end
      end
    end
  end
end
