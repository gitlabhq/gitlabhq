# frozen_string_literal: true

module Gitlab
  class BlamePresenter < Gitlab::View::Presenter::Simple
    include ActionView::Helpers::UrlHelper
    include ActionView::Helpers::TranslationHelper
    include ActionView::Context
    include AvatarsHelper
    include BlameHelper
    include CommitsHelper
    include ApplicationHelper
    include TreeHelper
    include IconsHelper

    presents :blame

    CommitData = Struct.new(
      :author_avatar,
      :age_map_class,
      :commit_link,
      :commit_author_link,
      :project_blame_link,
      :time_ago_tooltip)

    def initialize(subject, **attributes)
      super

      @commits = {}
      precalculate_data_by_commit!
    end

    def groups
      @groups ||= blame.groups
    end

    def commit_data(commit)
      @commits[commit.id] ||= get_commit_data(commit)
    end

    private

    # Huge source files with a high churn rate (e.g. 'locale/gitlab.pot') could have
    # 10x times more blame groups than unique commits across all the groups.
    # That means we could cache per-commit data we need
    # to avoid recalculating it multiple times.
    # For such files, it could significantly improve the performance of the Blame.
    def precalculate_data_by_commit!
      groups.each { |group| commit_data(group[:commit]) }
    end

    def get_commit_data(commit)
      CommitData.new.tap do |data|
        data.author_avatar = author_avatar(commit, size: 36, has_tooltip: false, lazy: true)
        data.age_map_class = age_map_class(commit.committed_date, project_duration)
        data.commit_link = link_to commit.title, project_commit_path(project, commit.id), class: "cdark", title: commit.title
        data.commit_author_link = commit_author_link(commit, avatar: false)
        data.project_blame_link = project_blame_link(commit)
        data.time_ago_tooltip = time_ago_with_tooltip(commit.committed_date)
      end
    end

    def project_blame_link(commit)
      previous_commit_id = commit.parent_id
      return unless previous_commit_id

      link_to project_blame_path(project, tree_join(previous_commit_id, path)),
        title: _('View blame prior to this change'),
        aria: { label: _('View blame prior to this change') },
        data: { toggle: 'tooltip', placement: 'right', container: 'body' } do
          versions_sprite_icon
        end
    end

    def project_duration
      @project_duration ||= age_map_duration(groups, project)
    end

    def versions_sprite_icon
      @versions_sprite_icon ||= sprite_icon('doc-versions', css_class: 'doc-versions align-text-bottom')
    end
  end
end
