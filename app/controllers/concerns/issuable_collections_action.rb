# frozen_string_literal: true

module IssuableCollectionsAction
  extend ActiveSupport::Concern
  include IssuableCollections
  include IssuesCalendar

  included do
    before_action :check_search_rate_limit!, only: [:issues, :merge_requests, :search_merge_requests], if: -> {
      params[:search].present?
    }
  end

  # rubocop:disable Gitlab/ModuleWithInstanceVariables
  def issues
    respond_to do |format|
      format.html
      format.atom do
        @issues = issuables_collection
                  .non_archived
                  .page(params[:page])

        @issuable_meta_data = Gitlab::IssuableMetadata.new(current_user, @issues).data

        render layout: 'xml'
      end
    end
  end
  # rubocop:enable Gitlab/ModuleWithInstanceVariables

  def merge_requests
    render_merge_requests
  end

  def issues_calendar
    render_issues_calendar(issuables_collection)
  end

  private

  def sorting_field
    case action_name
    when 'issues'
      Issue::SORTING_PREFERENCE_FIELD
    when 'merge_requests', 'search_merge_requests'
      MergeRequest::SORTING_PREFERENCE_FIELD
    end
  end

  def finder_type
    case action_name
    when 'issues', 'issues_calendar'
      IssuesFinder
    when 'merge_requests', 'search_merge_requests'
      MergeRequestsFinder
    end
  end

  def finder_options
    issue_types = Issue::TYPES_FOR_LIST

    super.merge(
      non_archived: true,
      issue_types: issue_types
    )
  end

  # rubocop:disable Gitlab/ModuleWithInstanceVariables
  def render_merge_requests
    @merge_requests = issuables_collection.page(params[:page])

    @issuable_meta_data = Gitlab::IssuableMetadata.new(current_user, @merge_requests).data
  rescue ActiveRecord::QueryCanceled => exception # rubocop:disable Database/RescueQueryCanceled
    log_exception(exception)

    @search_timeout_occurred = true
  end
  # rubocop:enable Gitlab/ModuleWithInstanceVariables
end
