# frozen_string_literal: true

class UserPresenter < Gitlab::View::Presenter::Delegated
  presents :user
end
