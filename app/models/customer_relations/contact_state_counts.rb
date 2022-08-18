# frozen_string_literal: true

module CustomerRelations
  class ContactStateCounts
    include Gitlab::Utils::StrongMemoize

    attr_reader :group

    def self.declarative_policy_class
      'CustomerRelations::ContactPolicy'
    end

    def initialize(current_user, group, params)
      @current_user = current_user
      @group = group
      @params = params
    end

    # Define method for each state
    ::CustomerRelations::Contact.states.each_key do |state|
      define_method(state) { counts[state] }
    end

    def all
      counts.values.sum
    end

    private

    attr_reader :current_user, :params

    def counts
      strong_memoize(:counts) do
        Hash.new(0).merge(counts_by_state)
      end
    end

    def counts_by_state
      ::Crm::ContactsFinder.counts_by_state(current_user, params.merge({ group: group }))
    end
  end
end
