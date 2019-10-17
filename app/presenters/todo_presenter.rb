# frozen_string_literal: true

class TodoPresenter < Gitlab::View::Presenter::Delegated
  include GlobalID::Identification

  presents :todo
end
