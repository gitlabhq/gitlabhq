# frozen_string_literal: true

class TodoPresenter < Gitlab::View::Presenter::Delegated
  presents ::Todo, as: :todo
end
