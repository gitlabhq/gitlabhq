# rubocop:disable Naming/FileName
# frozen_string_literal: true

# When switching to rails 5, we added migration version to all migration
# classes. This patch makes it possible to run versioned migrations
# also with rails 4

unless Gitlab.rails5?
  module ActiveRecord
    class Migration
      def self.[](version)
        Migration
      end
    end
  end
end
