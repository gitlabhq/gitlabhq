# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AutocompleteSources::ExpiresIn, feature_category: :global_search do
  controller(ActionController::Base) do
    include AutocompleteSources::ExpiresIn

    def members
      render json: []
    end

    def commands
      render json: []
    end

    def labels
      render json: []
    end

    def issues
      render json: []
    end

    def not_cached
      render json: []
    end
  end

  before do
    routes.draw do
      get "members" => "anonymous#members"
      get "commands" => "anonymous#commands"
      get "labels" => "anonymous#labels"
      get "issues" => "anonymous#issues"
      get "not_cached" => "anonymous#not_cached"
    end
  end

  let(:expected_cache_control) { "max-age=#{described_class::AUTOCOMPLETE_EXPIRES_IN}, private" }

  described_class::AUTOCOMPLETE_CACHED_ACTIONS.each do |action|
    context "when action is #{action} with feature flag enabled" do
      it "sets correct cache-control" do
        get action

        expect(response).to have_gitlab_http_status(:ok)
        expect(response.headers['Cache-Control']).to eq(expected_cache_control)
      end
    end
  end

  context 'when action is not in AUTOCOMPLETE_CACHED_ACTIONS' do
    it 'does not set cache-control' do
      get :not_cached

      expect(response).to have_gitlab_http_status(:ok)
      expect(response.headers['Cache-Control']).to be_nil
    end
  end
end
