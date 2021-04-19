# frozen_string_literal: true

class MergeRequest::MetricsFinder
  include Gitlab::Allowable

  def initialize(current_user, params = {})
    @current_user = current_user
    @params = params
  end

  def execute
    return klass.none if target_project.blank? || user_not_authorized?

    items = init_collection
    items = by_target_project(items)
    items = by_merged_after(items)
    by_merged_before(items)
  end

  private

  attr_reader :current_user, :params

  def by_target_project(items)
    items.by_target_project(target_project)
  end

  def by_merged_after(items)
    return items unless merged_after

    items.merged_after(merged_after)
  end

  def by_merged_before(items)
    return items unless merged_before

    items.merged_before(merged_before)
  end

  def user_not_authorized?
    !can?(current_user, :read_merge_request, target_project)
  end

  def init_collection
    klass.all
  end

  def klass
    MergeRequest::Metrics
  end

  def target_project
    params[:target_project]
  end

  def merged_after
    params[:merged_after]
  end

  def merged_before
    params[:merged_before]
  end
end
