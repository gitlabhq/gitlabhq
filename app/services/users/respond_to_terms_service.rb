# frozen_string_literal: true

module Users
  class RespondToTermsService
    def initialize(user, term)
      @user = user
      @term = term
    end

    # rubocop: disable CodeReuse/ActiveRecord
    def execute(accepted:)
      agreement = @user.term_agreements.find_or_initialize_by(term: @term)
      agreement.accepted = accepted

      if agreement.save
        store_accepted_term(accepted)
      end

      agreement
    end
    # rubocop: enable CodeReuse/ActiveRecord

    private

    def store_accepted_term(accepted)
      @user.update_column(:accepted_term_id, accepted ? @term.id : nil)
    end
  end
end
