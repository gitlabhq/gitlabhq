# frozen_string_literal: true

module RunnersHelper
  def runner_status_icon(runner)
    status = runner.status
    case status
    when :not_connected
      content_tag :i, nil,
                  class: "fa fa-warning",
                  title: "New runner. Has not connected yet"

    when :online, :offline, :paused
      content_tag :i, nil,
                  class: "fa fa-circle runner-status-#{status}",
                  title: "Runner is #{status}, last contact was #{time_ago_in_words(runner.contacted_at)} ago"
    end
  end

  def runner_link(runner)
    display_name = truncate(runner.display_name, length: 15)
    id = "\##{runner.id}"

    if current_user && current_user.admin
      link_to admin_runner_path(runner) do
        display_name + id
      end
    else
      display_name + id
    end
  end

  # Due to inability of performing sorting of runners by cached "contacted_at" values we have to show uncached values if sorting by "contacted_asc" is requested.
  # Please refer to the following issue for more details: https://gitlab.com/gitlab-org/gitlab-ce/issues/55920
  def runner_contacted_at(runner)
    if params[:sort] == 'contacted_asc'
      runner.uncached_contacted_at
    else
      runner.contacted_at
    end
  end
end
