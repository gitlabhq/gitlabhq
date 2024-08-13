# frozen_string_literal: true

module Gitlab
  class BlamePresenter < Gitlab::View::Presenter::Simple
    include ActionView::Helpers::TranslationHelper
    include ActionView::Context
    include AvatarsHelper
    include BlameHelper
    include CommitsHelper
    include ApplicationHelper
    include TreeHelper
    include IconsHelper

    presents nil, as: :blame

    CommitData = Struct.new(
      :author_avatar,
      :age_map_class,
      :commit_link,
      :commit_author_link,
      :project_blame_link,
      :time_ago_tooltip)

    def initialize(blame, **attributes)
      super

      @commits = {}
      precalculate_data_by_commit!
    end

    def first_line
      blame.first_line
    end

    def groups
      @groups ||= blame.groups
    end

    def commit_data(commit, previous_path = nil)
      @commits[commit.id] ||= get_commit_data(commit, previous_path)
    end

    def groups_commit_data
      groups.each { |group| group[:commit_data] = commit_data(group[:commit]) }
    end

    private

    # Huge source files with a high churn rate (e.g. 'locale/gitlab.pot') could have
    # 10x times more blame groups than unique commits across all the groups.
    # That means we could cache per-commit data we need
    # to avoid recalculating it multiple times.
    # For such files, it could significantly improve the performance of the Blame.
    def precalculate_data_by_commit!
      groups.each { |group| commit_data(group[:commit], group[:previous_path]) }
    end

    def get_commit_data(commit, previous_path = nil)
      CommitData.new.tap do |data|
        data.author_avatar = author_avatar(commit, size: 36, has_tooltip: false, lazy: true, project: project)
        data.age_map_class = age_map_class(commit.committed_date, project_duration)
        data.commit_link = link_to commit.title, project_commit_path(project, commit.id), title: commit.title
        data.commit_author_link = commit_author_link(commit, avatar: false)
        data.project_blame_link = project_blame_link(commit, previous_path)
        data.time_ago_tooltip = time_ago_with_tooltip(commit.committed_date)
      end
    end

    def project_blame_link(commit, previous_path = nil)
      previous_commit_id = commit.parent_id
      return unless previous_commit_id && !previous_path.nil?

      link_to project_blame_path(project, tree_join(previous_commit_id, previous_path), page: page),
        title: _('View blame prior to this change'),
        aria: { label: _('View blame prior to this change') },
        class: 'version-link',
        data: { toggle: 'tooltip', placement: 'right', container: 'body' } do
          '&nbsp;'.html_safe
        end
    end

    def project_duration
      @project_duration ||= age_map_duration(groups, project)
    end

    def link_to(*args, &block)
      ActionController::Base.helpers.link_to(*args, &block)
    end

    def mail_to(*args, &block)
      ActionController::Base.helpers.mail_to(*args, &block)
    end

    def project
      return super.project if defined?(super.project)

      blame.commit.repository.project
    end

    def page
      return super.page if defined?(super.page)

      nil
    end
  end
end
