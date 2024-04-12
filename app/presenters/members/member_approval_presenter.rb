# frozen_string_literal: true

module Members
  class MemberApprovalPresenter < ::Gitlab::View::Presenter::Delegated
    presents ::Members::MemberApproval, as: :member_approval
  end
end

Members::MemberApprovalPresenter.prepend_mod
