# frozen_string_literal: true

class ApplicationSetting
  class TermPolicy < BasePolicy
    include Gitlab::Utils::StrongMemoize

    condition(:current_terms, scope: :subject) do
      Gitlab::CurrentSettings.current_application_settings.latest_terms == @subject
    end

    condition(:terms_accepted, score: 1) do
      agreement&.accepted
    end

    rule { ~anonymous & current_terms }.policy do
      enable :accept_terms
      enable :decline_terms
    end

    rule { terms_accepted }.prevent :accept_terms

    # rubocop: disable CodeReuse/ActiveRecord
    def agreement
      strong_memoize(:agreement) do
        next nil if @user.nil? || @subject.nil?

        @user.term_agreements.find_by(term: @subject)
      end
    end
    # rubocop: enable CodeReuse/ActiveRecord
  end
end
