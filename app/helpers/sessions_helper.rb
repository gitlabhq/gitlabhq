# frozen_string_literal: true

module SessionsHelper
  def unconfirmed_email?
    flash[:alert] == t(:unconfirmed, scope: [:devise, :failure])
  end
end
