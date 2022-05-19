# frozen_string_literal: true

class NamespaceCiCdSetting < ApplicationRecord # rubocop:disable Gitlab/NamespacedClass
  belongs_to :namespace, inverse_of: :ci_cd_settings

  self.primary_key = :namespace_id
end

NamespaceCiCdSetting.prepend_mod
