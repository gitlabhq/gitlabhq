module IssuesAction
  extend ActiveSupport::Concern
  include IssuableCollections
  include IssuesCalendar

  # rubocop:disable Gitlab/ModuleWithInstanceVariables
  def issues
    @issues = issuables_collection
              .non_archived
              .page(params[:page])

    @issuable_meta_data = issuable_meta_data(@issues, collection_type)

    respond_to do |format|
      format.html
      format.atom { render layout: 'xml.atom' }
    end
  end
  # rubocop:enable Gitlab/ModuleWithInstanceVariables

  def issues_calendar
    render_issues_calendar(issuables_collection)
  end

  private

  def finder_type
    (super if defined?(super)) ||
      (IssuesFinder if %w(issues issues_calendar).include?(action_name))
  end
end
