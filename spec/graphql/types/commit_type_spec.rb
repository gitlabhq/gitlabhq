# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['Commit'] do
  specify { expect(described_class.graphql_name).to eq('Commit') }

  specify { expect(described_class).to require_graphql_authorizations(:download_code) }

  it 'contains attributes related to commit' do
    expect(described_class).to have_graphql_fields(
      :id, :sha, :title, :description, :description_html, :message, :title_html, :authored_date,
      :author_name, :author_gravatar, :author, :web_url, :web_path,
      :pipelines, :signature_html
    )
  end
end
