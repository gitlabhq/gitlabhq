# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::Projects::RepositoryLanguageType do
  specify { expect(described_class.graphql_name).to eq('RepositoryLanguage') }

  specify do
    expect(described_class).to have_graphql_fields(
      :name,
      :share,
      :color
    )
  end
end
