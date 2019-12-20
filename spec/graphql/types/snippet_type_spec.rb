# frozen_string_literal: true

require 'spec_helper'

describe GitlabSchema.types['Snippet'] do
  it 'has the correct fields' do
    expected_fields = [:id, :title, :project, :author,
                       :file_name, :content, :description,
                       :visibility_level, :created_at, :updated_at,
                       :web_url, :raw_url, :notes, :discussions,
                       :user_permissions, :description_html]

    is_expected.to have_graphql_fields(*expected_fields)
  end

  describe 'authorizations' do
    it { expect(described_class).to require_graphql_authorizations(:read_snippet) }
  end
end
