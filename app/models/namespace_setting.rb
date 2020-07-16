# frozen_string_literal: true

class NamespaceSetting < ApplicationRecord
  belongs_to :namespace, inverse_of: :namespace_settings

  self.primary_key = :namespace_id
end

NamespaceSetting.prepend_if_ee('EE::NamespaceSetting')
