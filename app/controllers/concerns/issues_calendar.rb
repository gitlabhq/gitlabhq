# frozen_string_literal: true

module IssuesCalendar
  extend ActiveSupport::Concern

  # rubocop:disable Gitlab/ModuleWithInstanceVariables
  def render_issues_calendar(issuables)
    @issues = issuables
                  .non_archived
                  .with_due_date
                  .limit(100)

    respond_to do |format|
      format.ics do
        # NOTE: with text/calendar as Content-Type, the browser always downloads
        #       the content as a file (even ignoring the Content-Disposition
        #       header). We want to display the content inline when accessed
        #       from GitLab, similarly to the RSS feed.
        response.headers['Content-Type'] = 'text/plain' if request.referer&.start_with?(::Settings.gitlab.base_url)
      end
    end
  end
  # rubocop:enable Gitlab/ModuleWithInstanceVariables
end
