# frozen_string_literal: true

module ActiveRecord
  module GitlabPatches
    # This adds `rescue_from` to ActiveRecord::Base.
    # Currently only the following places will be handled by `rescue_from`:
    #
    # - `ActiveRecord::Relation#load`, and other methods that call
    #   `ActiveRecord::Relation#exec_queries`.
    # - `ActiveModel::UnknownAttributeError` as a result of `ActiveRecord::Base#assign_attributes`
    #
    # class ApplicationRecord < ActiveRecord::Base
    #   rescue_from MyException, with: :my_handler
    #
    #   def my_handler(exception)
    #     Rails.logger.info exception.message
    #
    #     raise exception
    #   end
    # end
    module RescueFrom
      extend ActiveSupport::Concern

      prepended do |base|
        base.include ActiveSupport::Rescuable
      end
    end

    module ExecQueriesRescueWithHandler
      def exec_queries
        super
      rescue StandardError => e
        # Method klass is defined in ActiveRecord gem lib/active_record/relation.rb
        klass.rescue_with_handler(e) || raise
      end
    end

    module AssignAttributesRescueWithHandler
      def _assign_attributes(...)
        super(...)
      rescue StandardError => e
        rescue_with_handler(e) || raise
      end
    end
  end
end

ActiveSupport.on_load(:active_record) do
  ActiveRecord::Relation.prepend(ActiveRecord::GitlabPatches::ExecQueriesRescueWithHandler)
  ActiveRecord::Base.prepend(ActiveRecord::GitlabPatches::AssignAttributesRescueWithHandler)
  ActiveRecord::Base.prepend(ActiveRecord::GitlabPatches::RescueFrom)
end
