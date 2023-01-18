# frozen_string_literal: true

class EmailPolicy < BasePolicy # rubocop:disable Gitlab/NamespacedClass
  delegate { @subject.user }
end
