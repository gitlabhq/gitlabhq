# frozen_string_literal: true

class InvitationPresenter < Gitlab::View::Presenter::Delegated
  presents nil, as: :invitation
end
