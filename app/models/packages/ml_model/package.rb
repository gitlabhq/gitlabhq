# frozen_string_literal: true

module Packages
  module MlModel
    class Package < Packages::Package
      self.allow_legacy_sti_class = true

      after_create_commit :publish_creation_event

      has_one :model_version, class_name: "Ml::ModelVersion", inverse_of: :package

      validates :name,
        format: Gitlab::Regex.ml_model_name_regex,
        presence: true,
        length: { maximum: 255 }

      validates :version,
        format: Gitlab::Regex.ml_model_version_name_regex,
        presence: true,
        length: { maximum: 255 }
    end
  end
end
