# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['Commit'], feature_category: :source_code_management do
  include GraphqlHelpers

  specify { expect(described_class.graphql_name).to eq('Commit') }

  specify { expect(described_class).to require_graphql_authorizations(:read_code) }

  specify { expect(described_class).to include(Types::TodoableInterface) }

  it 'contains attributes related to commit' do
    expect(described_class).to have_graphql_fields(
      :id, :parent_sha, :sha, :short_id, :title, :full_title, :full_title_html,
      :description, :description_html, :message, :title_html, :authored_date,
      :author_name, :author_email, :author_gravatar, :author, :diffs, :web_url,
      :web_path, :pipelines, :latest_pipeline, :signature_html, :signature, :committer_name,
      :committer_email, :committed_date, :name, :tags, :has_agent_session,
      # Provided by Types::Notes::NoteableInterface (Commit is a noteable).
      :notes, :discussions, :commenters
    )
  end

  describe 'diffs' do
    it 'limits field call count' do
      expect(described_class.fields['diffs'].extensions).to include(a_kind_of(::Gitlab::Graphql::Limit::FieldCallCount))
    end
  end

  describe '#latest_pipeline' do
    let_it_be(:project) { create(:project, :repository) }
    let_it_be(:user) { project.first_owner }
    let_it_be(:commit) { project.commit }

    # `latest_pipeline_per_commit` orders by `id DESC` (not a timestamp), and
    # `let_it_be` runs these blocks in definition order, so `policy_pipeline` is
    # always created after `ci_pipeline` and gets the higher `id`. Ordering is
    # therefore deterministic regardless of `created_at` resolution.

    # The real CI pipeline that determines the commit status; created first (lower id), failed.
    let_it_be(:ci_pipeline) do
      create(:ci_pipeline, project: project, sha: commit.sha, ref: project.default_branch,
        status: :failed, source: :push)
    end

    # A dangling pipeline (e.g. a security policy scan); created last (higher id) and green.
    # A naive "newest pipeline of any source" would return this; `ci_sources` scoping is the
    # only reason the failed `ci_pipeline` wins instead, which is what this test asserts.
    let_it_be(:policy_pipeline) do
      create(:ci_pipeline, project: project, sha: commit.sha, ref: project.default_branch,
        status: :success, source: :security_orchestration_policy)
    end

    it 'returns the latest CI-source pipeline and ignores dangling pipelines' do
      result = resolve_field(:latest_pipeline, commit, current_user: user, object_type: described_class)

      expect(::Gitlab::Graphql::Lazy.force(result)).to eq(ci_pipeline)
    end
  end
end
