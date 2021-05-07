# frozen_string_literal: true

class UpdateGitlabSubscriptionsStartAtPostEoa < ActiveRecord::Migration[6.0]
  UPDATE_BATCH_SIZE = 100

  disable_ddl_transaction!

  class Plan < ActiveRecord::Base
    self.table_name = 'plans'
    self.inheritance_column = :_type_disabled
  end

  class GitlabSubscription < ActiveRecord::Base
    include EachBatch

    self.table_name = 'gitlab_subscriptions'
    self.inheritance_column = :_type_disabled

    EOA_ROLLOUT_DATE = '2021-01-26'

    scope :with_plan, -> (from_plan) do
      where("start_date >= ? AND hosted_plan_id = ?", EOA_ROLLOUT_DATE, from_plan.id)
    end
  end

  def up
    return unless Gitlab.com?

    silver_plan = Plan.find_by(name: 'silver')
    gold_plan = Plan.find_by(name: 'gold')
    premium_plan = Plan.find_by(name: 'premium')
    ultimate_plan = Plan.find_by(name: 'ultimate')

    # Silver to Premium
    update_hosted_plan_for_subscription(from_plan: silver_plan, to_plan: premium_plan)

    # Gold to Ultimate
    update_hosted_plan_for_subscription(from_plan: gold_plan, to_plan: ultimate_plan)
  end

  def down
    # no-op
  end

  private

  def update_hosted_plan_for_subscription(from_plan:, to_plan:)
    return unless from_plan && to_plan

    GitlabSubscription.with_plan(from_plan).each_batch(of: UPDATE_BATCH_SIZE) do |batch|
      batch.update_all(hosted_plan_id: to_plan.id)
    end
  end
end
