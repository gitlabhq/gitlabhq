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
    @acme_order ||= PagesDomainAcmeOrder.find_by_domain_and_token(params[:domain], params[:token])
  end
end
