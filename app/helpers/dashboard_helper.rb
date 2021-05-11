# frozen_string_literal: true

module DashboardHelper
  include IconsHelper

  def assigned_issues_dashboard_path
    issues_dashboard_path(assignee_username: current_user.username)
  end

  def assigned_mrs_dashboard_path
    merge_requests_dashboard_path(assignee_username: current_user.username)
  end

  def reviewer_mrs_dashboard_path
    merge_requests_dashboard_path(reviewer_username: current_user.username)
  end

  def dashboard_nav_links
    @dashboard_nav_links ||= get_dashboard_nav_links
  end

  def dashboard_nav_link?(link)
    dashboard_nav_links.include?(link)
  end

  def any_dashboard_nav_link?(links)
    links.any? { |link| dashboard_nav_link?(link) }
  end

  def has_start_trial?
    false
  end

  def feature_entry(title, href: nil, enabled: true, doc_href: nil)
    enabled_text = enabled ? 'on' : 'off'
    label = "#{title}: status #{enabled_text}"
    link_or_title = href && enabled ? tag.a(title, href: href) : title

    tag.p(aria: { label: label }) do
      concat(link_or_title)

      concat(tag.span(class: %w[light float-right]) do
        boolean_to_icon(enabled)
      end)

      if doc_href.present?
        link_to_doc = link_to(sprite_icon('question'), doc_href,
                              class: 'gl-ml-2', title: _('Documentation'),
                              target: '_blank', rel: 'noopener noreferrer')

        concat(link_to_doc)
      end
    end
  end

  private

  def get_dashboard_nav_links
    links = [:projects, :groups, :snippets]

    if can?(current_user, :read_cross_project)
      links += [:activity, :milestones]
    end

    links
  end
end

DashboardHelper.prepend_mod_with('DashboardHelper')
