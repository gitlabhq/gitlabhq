# frozen_string_literal: true

module VersionedDescription
  extend ActiveSupport::Concern

  included do
    attr_accessor :saved_description_version
    attr_accessor :skip_description_version

    has_many :description_versions

    after_update :save_description_version, unless: :skip_description_version
  end

  private

  def save_description_version
    self.saved_description_version = nil

    return unless saved_change_to_description?

    unless description_versions.exists?
      description_versions.create!(
        description: description_before_last_save,
        created_at: created_at
      )
    end

    self.saved_description_version = description_versions.create!(description: description)
  end
end
