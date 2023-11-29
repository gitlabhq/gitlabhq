# frozen_string_literal: true

module Packages
  module MlModel
    class Package < Packages::Package
      self.allow_legacy_sti_class = true

      has_one :model_version, class_name: "Ml::ModelVersion", inverse_of: :package

      validates :name,
        format: Gitlab::Regex.ml_model_name_regex,
        presence: true,
        length: { maximum: 255 }

      validates :version,
        format: Gitlab::Regex.semver_regex,
        presence: true,
        length: { maximum: 255 }
    end
  end
end
