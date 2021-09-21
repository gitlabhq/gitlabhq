# frozen_string_literal: true

class BoardPresenter < Gitlab::View::Presenter::Delegated
  presents ::Board, as: :board
end
