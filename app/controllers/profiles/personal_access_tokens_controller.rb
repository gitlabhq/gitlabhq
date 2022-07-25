# frozen_string_literal: true

class Profiles::PersonalAccessTokensController < Profiles::ApplicationController
  feature_category :authentication_and_authorization

  def index
    set_index_vars
    scopes = params[:scopes].split(',').map(&:squish).select(&:present?).map(&:to_sym) unless params[:scopes].nil?
    @personal_access_token = finder.build(
      name: params[:name],
      scopes: scopes
    )

    respond_to do |format|
      format.html
      format.json do
        render json: @active_personal_access_tokens
      end
    end
  end

  def create
    result = ::PersonalAccessTokens::CreateService.new(
      current_user: current_user, target_user: current_user, params: personal_access_token_params
    ).execute

    @personal_access_token = result.payload[:personal_access_token]

    if result.success?
      render json: { new_token: @personal_access_token.token,
                     active_access_tokens: active_personal_access_tokens }, status: :ok
    else
      render json: { errors: result.errors }, status: :unprocessable_entity
    end
  end

  def revoke
    @personal_access_token = finder.find(params[:id])
    service = PersonalAccessTokens::RevokeService.new(current_user, token: @personal_access_token).execute
    service.success? ? flash[:notice] = service.message : flash[:alert] = service.message

    redirect_to profile_personal_access_tokens_path
  end

  private

  def finder(options = {})
    PersonalAccessTokensFinder.new({ user: current_user, impersonation: false }.merge(options))
  end

  def personal_access_token_params
    params.require(:personal_access_token).permit(:name, :expires_at, scopes: [])
  end

  def set_index_vars
    @scopes = Gitlab::Auth.available_scopes_for(current_user)
    @active_personal_access_tokens = active_personal_access_tokens
  end

  def active_personal_access_tokens
    tokens = finder(state: 'active', sort: 'expires_at_asc_id_desc').execute

    if Feature.enabled?('access_token_pagination')
      tokens = tokens.page(page)
      add_pagination_headers(tokens)
    end

    ::API::Entities::PersonalAccessTokenWithDetails.represent(tokens)
  end

  def add_pagination_headers(relation)
    Gitlab::Pagination::OffsetHeaderBuilder.new(
      request_context: self,
      per_page: relation.limit_value,
      page: relation.current_page,
      next_page: relation.next_page,
      prev_page: relation.prev_page,
      total: relation.total_count,
      params: params.permit(:page)
    ).execute
  end

  def page
    (params[:page] || 1).to_i
  end
end
