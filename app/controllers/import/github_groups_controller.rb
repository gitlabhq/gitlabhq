# frozen_string_literal: true

module Import
  class GithubGroupsController < ApplicationController
    include Import::GithubOauth

    before_action :provider_auth, only: [:status]
    feature_category :importers

    PAGE_LENGTH = 25

    def status
      respond_to do |format|
        format.json do
          render json: { provider_groups: serialized_provider_groups }
        end
      end
    end

    private

    def serialized_provider_groups
      Import::GithubOrgSerializer.new.represent(importable_orgs)
    end

    def importable_orgs
      client_orgs.map(&:to_h)
    end

    def client_orgs
      @client_orgs ||= client.octokit.organizations(nil, pagination_options)
    end

    def client
      @client ||= Gitlab::GithubImport::Client.new(session[access_token_key])
    end

    def pagination_options
      {
        page: [1, pagination_params[:page].to_i].max,
        per_page: PAGE_LENGTH
      }
    end

    def auth_state_key
      :"#{provider_name}_auth_state_key"
    end

    def access_token_key
      :"#{provider_name}_access_token"
    end

    def provider_name
      :github
    end
  end
end
