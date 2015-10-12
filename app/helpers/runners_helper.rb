module RunnersHelper
  def runner_status_icon(runner)
    status = runner.status
    case status
    when :not_connected
      content_tag :i, nil,
                  class: "fa fa-warning-sign",
                  title: "New runner. Has not connected yet"

    when :online, :offline, :paused
      content_tag :i, nil,
                  class: "fa fa-circle runner-status-#{status}",
                  title: "Runner is #{status}, last contact was #{time_ago_in_words(runner.contacted_at)} ago"
    end
  end
end
