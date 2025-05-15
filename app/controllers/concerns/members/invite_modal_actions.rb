# frozen_string_literal: true

module Members
  module InviteModalActions
    extend ActiveSupport::Concern

    def invite_search
      users = Members::InviteUsersFinder.new(current_user, source, search: invite_search_params[:search]).execute
        .page(1)
        .per(invite_search_per_page)

      render json: UserSerializer.new.represent(users)
    end

    private

    def invite_search_per_page
      (pagination_params[:per_page] || 20).to_i
    end

    def invite_search_params
      params.permit(:search)
    end
  end
end
