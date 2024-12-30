# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['Commit'], feature_category: :source_code_management do
  specify { expect(described_class.graphql_name).to eq('Commit') }

  specify { expect(described_class).to require_graphql_authorizations(:read_code) }

  specify { expect(described_class).to include(Types::TodoableInterface) }

  it 'contains attributes related to commit' do
    expect(described_class).to have_graphql_fields(
      :id, :sha, :short_id, :title, :full_title, :full_title_html, :description, :description_html, :message,
      :title_html, :authored_date,
      :author_name, :author_email, :author_gravatar, :author, :diffs, :web_url, :web_path,
      :pipelines, :signature_html, :signature, :committer_name, :committer_email, :committed_date,
      :name
    )
  end

  describe 'diffs' do
    it 'limits field call count' do
      expect(described_class.fields['diffs'].extensions).to include(a_kind_of(::Gitlab::Graphql::Limit::FieldCallCount))
    end
  end
end
