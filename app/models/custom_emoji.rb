# frozen_string_literal: true

class CustomEmoji < ApplicationRecord
  NAME_REGEXP = /[a-z0-9_-]+/.freeze

  belongs_to :namespace, inverse_of: :custom_emoji

  belongs_to :group, -> { where(type: Group.sti_name) }, foreign_key: 'namespace_id'
  belongs_to :creator, class_name: "User", inverse_of: :created_custom_emoji

  # For now only external emoji are supported. See https://gitlab.com/gitlab-org/gitlab/-/issues/230467
  validates :external, inclusion: { in: [true] }

  validates :file, public_url: true, if: :external

  validate :valid_emoji_name

  validates :group, presence: true
  validates :creator, presence: true
  validates :name,
    uniqueness: { scope: [:namespace_id, :name] },
    presence: true,
    length: { maximum: 36 },

    format: { with: /\A#{NAME_REGEXP}\z/o }

  scope :by_name, -> (names) { where(name: names) }

  alias_attribute :url, :file # this might need a change in https://gitlab.com/gitlab-org/gitlab/-/issues/230467

  # Find custom emoji for the given resource.
  # A resource can be either a Project or a Group, or anything responding to #root_ancestor.
  # Usually it's the return value of #resource_parent on any model.
  scope :for_resource, -> (resource) do
    return none if resource.nil?

    namespace = resource.root_ancestor

    return none if namespace.nil? || Feature.disabled?(:custom_emoji, namespace)

    namespace.custom_emoji
  end

  private

  def valid_emoji_name
    if TanukiEmoji.find_by_alpha_code(name)
      errors.add(:name, _('%{name} is already being used for another emoji') % { name: self.name })
    end
  end
end
