# frozen_string_literal: true

module Gitlab
  module AlertManagement
    # Represents counts of each status or category of statuses
    class AlertStatusCounts
      include Gitlab::Utils::StrongMemoize

      attr_reader :project

      def self.declarative_policy_class
        'AlertManagement::AlertPolicy'
      end

      def initialize(current_user, project, params)
        @project = project
        @current_user = current_user
        @params = params
      end

      # Define method for each status
      ::AlertManagement::Alert.status_names.each do |status|
        define_method(status) { counts[status] }
      end

      def open
        counts[:triggered] + counts[:acknowledged]
      end

      def all
        counts.values.sum
      end

      private

      attr_reader :current_user, :params

      def counts
        strong_memoize(:counts) do
          Hash.new(0).merge(counts_by_status)
        end
      end

      def counts_by_status
        ::AlertManagement::AlertsFinder.counts_by_status(current_user, project, params)
      end
    end
  end
end
