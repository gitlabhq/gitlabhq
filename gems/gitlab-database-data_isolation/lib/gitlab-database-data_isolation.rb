# frozen_string_literal: true

require "active_record"
require_relative "gitlab/database/data_isolation/version"
require_relative "gitlab/database/data_isolation/configuration"
require_relative "gitlab/database/data_isolation/context"
require_relative "gitlab/database/data_isolation/scope_helper"
require_relative "gitlab/database/data_isolation/strategies/arel"

module Gitlab
  module Database
    module DataIsolation
      class << self
        def configuration
          @configuration ||= Configuration.new
        end

        def configure
          yield(configuration)
        end

        def reset_configuration!
          @configuration = Configuration.new
        end

        def install!
          return if @installed

          ActiveRecord::Relation.prepend(Strategies::Arel::ActiveRecordExtension)
          @installed = true
        end
      end
    end
  end
end
