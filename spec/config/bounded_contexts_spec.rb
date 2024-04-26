# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe 'bounded_contexts.yml', feature_category: :shared do
  contexts = YAML.load_file(Rails.root.join('config/bounded_contexts.yml'))
  feature_categories = YAML.load_file(Rails.root.join('config/feature_categories.yml'))
  domains = contexts.fetch('domains')
  platform_libs = contexts.fetch('platform')

  it 'contains entries' do
    expect(domains).not_to be_empty
    expect(platform_libs).not_to be_empty
  end

  it 'does not contain duplicate entries between domains and platform' do
    duplicates = domains.keys & platform_libs.keys

    expect(duplicates).to be_empty,
      "Duplicate entries between domains and platform found: #{duplicates.join(', ')}"
  end

  domains.each do |name, domain|
    describe "Domain `#{name}`" do
      it 'has a valid name' do
        expect(name).not_to include('::'), 'domain name must be a top-level Ruby constant'
        expect(name).to eq(name.camelcase), 'name must be camel case'
      end

      it 'contains a description and a list of related feature categories' do
        expect(domain.keys).to contain_exactly('description', 'feature_categories')
        expect(domain['feature_categories']).not_to be_blank
        expect(feature_categories).to include(*domain['feature_categories'])

        # TODO: ensure that `description` is not empty
        # expect(domain['description']).not_to be_empty
      end
    end
  end

  platform_libs.each do |name, lib|
    describe "Platform lib `#{name}`" do
      it 'has a valid name' do
        expect(name).to eq(name.camelcase), 'name must be camel case'
      end

      it 'contains at least a description' do
        expect(lib).not_to be_empty
        expect(lib.keys).to include('description')

        # TODO: ensure that `description` is not empty
        # expect(lib['description']).not_to be_empty
      end
    end
  end
end
