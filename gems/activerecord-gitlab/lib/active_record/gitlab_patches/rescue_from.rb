# frozen_string_literal: true

module ActiveRecord
  module GitlabPatches
    # This adds `rescue_from` to ActiveRecord::Base.
    # Currently, only errors called from `ActiveRecord::Relation#exec_queries`
    # will be handled by `rescue_from`.
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
        klass.rescue_with_handler(e) || raise
      end
    end
  end
end

ActiveSupport.on_load(:active_record) do
  ActiveRecord::Relation.prepend(ActiveRecord::GitlabPatches::ExecQueriesRescueWithHandler)
  ActiveRecord::Base.prepend(ActiveRecord::GitlabPatches::RescueFrom)
end
