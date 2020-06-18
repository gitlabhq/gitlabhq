# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'GraphiQL' do
  context 'without relative_url_root' do
    before do
      visit '/-/graphql-explorer'
    end

    it 'has the correct graphQLEndpoint' do
      expect(page.body).to include('var graphQLEndpoint = "/api/graphql";')
    end
  end

  context 'with relative_url_root' do
    before do
      stub_config_setting(relative_url_root: '/gitlab/root')
      Rails.application.reload_routes!

      visit '/-/graphql-explorer'
    end

    after do
      Rails.application.reload_routes!
    end

    it 'has the correct graphQLEndpoint' do
      expect(page.body).to include('var graphQLEndpoint = "/gitlab/root/api/graphql";')
    end
  end
end
