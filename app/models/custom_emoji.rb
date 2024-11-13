# frozen_string_literal: true

class CustomEmoji < ApplicationRecord
  NAME_REGEXP = /[a-z0-9_-]+/

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

  scope :by_name, ->(names) { where(name: names) }
  scope :for_namespaces, ->(namespace_ids) do
    order = Gitlab::Pagination::Keyset::Order.build([
      Gitlab::Pagination::Keyset::ColumnOrderDefinition.new(
        attribute_name: 'name',
        order_expression: CustomEmoji.arel_table[:name].asc,
        nullable: :not_nullable
      ),
      Gitlab::Pagination::Keyset::ColumnOrderDefinition.new(
        attribute_name: 'current_namespace',
        order_expression: Arel::Nodes::Case.new.when(
          CustomEmoji.arel_table[:namespace_id].eq(namespace_ids.first)
        ).then(0).else(1).asc,
        nullable: :not_nullable,
        add_to_projections: true
      )
    ])
    where(namespace_id: namespace_ids)
      .select("DISTINCT ON (name) *")
      .order(order)
  end

  scope :for_resource, ->(resource) do
    return none if resource.nil?
    return none unless resource.is_a?(Group)

    resource.custom_emoji
  end

  def url
    Gitlab::AssetProxy.proxy_url(file)
  end

  private

  def valid_emoji_name
    if TanukiEmoji.find_by_alpha_code(name)
      errors.add(:name, _('%{name} is already being used for another emoji') % { name: self.name })
    end
  end
end
