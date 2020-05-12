# frozen_string_literal: true

require 'spec_helper'

describe GitlabSchema.types['Commit'] do
  specify { expect(described_class.graphql_name).to eq('Commit') }

  specify { expect(described_class).to require_graphql_authorizations(:download_code) }

  it 'contains attributes related to commit' do
    expect(described_class).to have_graphql_fields(
      :id, :sha, :title, :description, :message, :authored_date,
      :author_name, :author_gravatar, :author, :web_url, :latest_pipeline,
      :pipelines, :signature_html
    )
  end
end
