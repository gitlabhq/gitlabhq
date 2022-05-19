# frozen_string_literal: true

class NamespaceCiCdSettingPolicy < BasePolicy # rubocop:disable Gitlab/NamespacedClass
  delegate { @subject.namespace }
end
