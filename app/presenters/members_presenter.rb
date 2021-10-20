# frozen_string_literal: true

class MembersPresenter < Gitlab::View::Presenter::Delegated
  include Enumerable

  presents nil, as: :members

  def to_ary
    to_a
  end

  def each
    members.each do |member|
      yield member.present(current_user: current_user)
    end
  end
end
