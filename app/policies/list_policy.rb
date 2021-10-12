# frozen_string_literal: true

class ListPolicy < BasePolicy # rubocop:disable Gitlab/NamespacedClass
  delegate { @subject.board.resource_parent }
end
