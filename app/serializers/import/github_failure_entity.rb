# frozen_string_literal: true

module Import
  class GithubFailureEntity < Grape::Entity
    expose :type do |failure|
      failure.external_identifiers['object_type']
    end

    expose :title do |failure|
      title(failure)
    end

    expose :provider_url do |failure|
      build_url(failure)
    end

    expose :details do
      expose :exception_class
      expose :exception_message
      expose :correlation_id_value
      expose :source
      expose :created_at
      expose :github_identifiers do
        with_options(expose_nil: false) do
          expose(:object_type) { |failure| failure.external_identifiers['object_type'] }
          expose(:id) { |failure| failure.external_identifiers['id'] }
          expose(:db_id) { |failure| failure.external_identifiers['db_id'] }
          expose(:iid) { |failure| failure.external_identifiers['iid'] }
          expose(:title) { |failure| failure.external_identifiers['title'] }
          expose(:login) { |failure| failure.external_identifiers['login'] }
          expose(:event) { |failure| failure.external_identifiers['event'] }
          expose(:merge_request_id) { |failure| failure.external_identifiers['merge_request_id'] }
          expose(:merge_request_iid) { |failure| failure.external_identifiers['merge_request_iid'] }
          expose(:requested_reviewers) { |failure| failure.external_identifiers['requested_reviewers'] }
          expose(:note_id) { |failure| failure.external_identifiers['note_id'] }
          expose(:noteable_type) { |failure| failure.external_identifiers['noteable_type'] }
          expose(:noteable_iid) { |failure| failure.external_identifiers['noteable_iid'] }
          expose(:issuable_type) { |failure| failure.external_identifiers['issuable_type'] }
          expose(:issuable_iid) { |failure| failure.external_identifiers['issuable_iid'] }
          expose(:review_id) { |failure| failure.external_identifiers['review_id'] }
          expose(:tag) { |failure| failure.external_identifiers['tag'] }
          expose(:oid) { |failure| failure.external_identifiers['oid'] }
          expose(:size) { |failure| failure.external_identifiers['size'] }
        end
      end
    end

    private

    # rubocop:disable Metrics/CyclomaticComplexity
    def title(failure)
      gh_identifiers = failure.external_identifiers

      case gh_identifiers['object_type']
      when 'pull_request', 'issue', 'label', 'milestone'
        gh_identifiers['title']
      when 'pull_request_merged_by'
        format(s_("GithubImporter|Pull request %{pull_request_iid} merger"), pull_request_iid: gh_identifiers['iid'])
      when 'pull_request_review_request'
        format(
          s_("GithubImporter|Pull request %{pull_request_iid} review request"),
          pull_request_iid: gh_identifiers['merge_request_iid']
        )
      when 'pull_request_review'
        format(s_("GithubImporter|Pull request review %{review_id}"), review_id: gh_identifiers['review_id'])
      when 'collaborator'
        gh_identifiers['login']
      when 'protected_branch'
        gh_identifiers['id']
      when 'issue_event'
        gh_identifiers['event']
      when 'release'
        gh_identifiers['tag']
      when 'note'
        format(
          s_("GithubImporter|%{noteable_type} comment %{note_id}"),
          noteable_type: gh_identifiers['noteable_type'],
          note_id: gh_identifiers['note_id']
        )
      when 'diff_note'
        format(s_("GithubImporter|Pull request review comment %{note_id}"), note_id: gh_identifiers['note_id'])
      when 'issue_attachment'
        format(s_("GithubImporter|Issue %{issue_iid} attachment"), issue_iid: gh_identifiers['noteable_iid'])
      when 'merge_request_attachment'
        format(
          s_("GithubImporter|Merge request %{merge_request_iid} attachment"),
          merge_request_iid: gh_identifiers['noteable_iid']
        )
      when 'release_attachment'
        format(s_("GithubImporter|Release %{tag} attachment"), tag: gh_identifiers['tag'])
      when 'note_attachment'
        s_('GithubImporter|Note attachment')
      when 'lfs_object'
        gh_identifiers['oid'].to_s
      else
        ''
      end
    end

    def build_url(failure)
      project = failure.project
      gh_identifiers = failure.external_identifiers
      github_repo = project.import_source

      host = host(project.import_url)
      return '' unless host

      case gh_identifiers['object_type']
      when 'pull_request', 'pull_request_merged_by'
        # https://github.com/OWNER/REPO/pull/1
        "#{host}/#{github_repo}/pull/#{gh_identifiers['iid']}"
      when 'pull_request_review_request'
        # https://github.com/OWNER/REPO/pull/1
        "#{host}/#{github_repo}/pull/#{gh_identifiers['merge_request_iid']}"
      when 'pull_request_review'
        # https://github.com/OWNER/REPO/pull/1#pullrequestreview-1219894643
        "#{host}/#{github_repo}/pull/#{gh_identifiers['merge_request_iid']}" \
        "#pullrequestreview-#{gh_identifiers['review_id']}"
      when 'issue'
        # https://github.com/OWNER/REPO/issues/1
        "#{host}/#{github_repo}/issues/#{gh_identifiers['iid']}"
      when 'collaborator'
        # https://github.com/USER_NAME
        "#{host}/#{gh_identifiers['login']}"
      when 'protected_branch'
        branch = escape(gh_identifiers['id'])

        # https://github.com/OWNER/REPO/tree/BRANCH_NAME
        "#{host}/#{github_repo}/tree/#{branch}"
      when 'issue_event'
        # https://github.com/OWNER/REPO/issues/1#event-8356623615
        "#{host}/#{github_repo}/issues/#{gh_identifiers['issuable_iid']}#event-#{gh_identifiers['id']}"
      when 'label'
        label = escape(gh_identifiers['title'])

        # https://github.com/OWNER/REPO/labels/bug
        "#{host}/#{github_repo}/labels/#{label}"
      when 'milestone'
        # https://github.com/OWNER/REPO/milestone/1
        "#{host}/#{github_repo}/milestone/#{gh_identifiers['iid']}"
      when 'release', 'release_attachment'
        tag = escape(gh_identifiers['tag'])

        # https://github.com/OWNER/REPO/releases/tag/v1.0
        "#{host}/#{github_repo}/releases/tag/#{tag}"
      when 'note'
        # https://github.com/OWNER/REPO/issues/2#issuecomment-1480755368
        "#{host}/#{github_repo}/issues/#{gh_identifiers['noteable_iid']}#issuecomment-#{gh_identifiers['note_id']}"
      when 'diff_note'
        # https://github.com/OWNER/REPO/pull/1#discussion_r1050098241
        "#{host}/#{github_repo}/pull/#{gh_identifiers['noteable_iid']}#discussion_r#{gh_identifiers['note_id']}"
      when 'issue_attachment'
        # https://github.com/OWNER/REPO/issues/1
        "#{host}/#{github_repo}/issues/#{gh_identifiers['noteable_iid']}"
      when 'merge_request_attachment'
        # https://github.com/OWNER/REPO/pull/1
        "#{host}/#{github_repo}/pull/#{gh_identifiers['noteable_iid']}"
      when 'lfs_object', 'note_attachment'
        # we can't build url to lfs objects and note attachments
        ''
      else
        ''
      end
    end
    # rubocop:enable Metrics/CyclomaticComplexity

    def host(uri)
      parsed_uri = URI.parse(uri)
      "#{parsed_uri.scheme}://#{parsed_uri.hostname}"
    rescue URI::InvalidURIError
      nil
    end

    def escape(str)
      CGI.escape(str)
    end
  end
end
