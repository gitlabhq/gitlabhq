# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'seed production programming languages', feature_category: :source_code_management do
  let(:programming_languages_fixture) do
    Rails.root.join('db/fixtures/production/004_programming_languages.rb')
  end

  subject(:load_fixture) { load(programming_languages_fixture) }

  it 'invokes the programming languages importer' do
    expect(Gitlab::DatabaseImporters::ProgrammingLanguagesImporter).to receive(:import)

    load_fixture
  end
end
