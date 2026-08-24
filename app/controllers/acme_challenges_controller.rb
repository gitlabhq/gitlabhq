# frozen_string_literal: true

class AcmeChallengesController < BaseActionController
  def show
    if acme_order
      render plain: acme_order.challenge_file_content, content_type: 'text/plain'
    else
      head :not_found
    end
  end

  private

  def acme_order
    @acme_order ||= PagesDomainAcmeOrder.find_by_domain_and_token(
      acme_order_params[:domain], acme_order_params[:token]
    )
  end

  def acme_order_params
    params.permit(:domain, :token)
  end
end
