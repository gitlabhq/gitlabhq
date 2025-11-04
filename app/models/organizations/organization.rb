# frozen_string_literal: true

module Organizations
  class Organization < ApplicationRecord
    include Gitlab::Utils::StrongMemoize
    include Gitlab::SQL::Pattern
    include Gitlab::VisibilityLevel
    include Gitlab::Routing.url_helpers
    include FeatureGate
    include Organizations::Isolatable

    DEFAULT_ORGANIZATION_ID = 1

    scope :without_default, -> { id_not_in(DEFAULT_ORGANIZATION_ID) }
    scope :with_namespace_path, ->(path) {
      joins(namespaces: :route).where(route: { path: path.to_s })
    }
    scope :with_user, ->(user) {
      joins(:organization_users).merge(Organizations::OrganizationUser.by_user(user))
                                .order(:id)
    }

    before_destroy :check_if_default_organization

    has_many :namespaces
    has_many :groups
    has_many :root_groups, -> { roots }, class_name: 'Group', inverse_of: :organization
    has_many :pool_repositories
    has_many :projects
    has_many :snippets
    has_many :snippet_repositories, inverse_of: :organization
    has_many :topics, class_name: "Projects::Topic"
    has_many :integrations
    has_many :system_hooks

    has_one :settings, class_name: "OrganizationSetting"
    has_one :isolated_record, class_name: 'Organizations::OrganizationIsolation',
      inverse_of: :organization, autosave: true

    has_one :organization_detail, inverse_of: :organization, autosave: true

    has_many :organization_users, inverse_of: :organization
    has_many :organization_user_details, inverse_of: :organization
    # if considering disable_joins on the below see:
    # https://gitlab.com/gitlab-org/gitlab/-/merge_requests/140343#note_1705047949
    has_many :users, through: :organization_users, inverse_of: :organizations

    validates :name,
      presence: true,
      length: { maximum: 255 }

    validates :path,
      presence: true,
      uniqueness: { case_sensitive: false },
      'organizations/path': true,
      length: { minimum: 2, maximum: 255 }

    validate :check_visibility_level, if: -> { new_record? || visibility_level_changed? }
    validate :check_organization_reserved_name, if: -> { new_record? }

    delegate :description, :description_html, :avatar, :avatar_url, :remove_avatar!, to: :organization_detail

    accepts_nested_attributes_for :organization_detail
    accepts_nested_attributes_for :organization_users

    def self.search(query, use_minimum_char_limit: true)
      fuzzy_search(query, [:name, :path], use_minimum_char_limit: use_minimum_char_limit)
    end

    def self.default_organization
      find_by(id: DEFAULT_ORGANIZATION_ID)
    end

    def self.default?(id)
      id == DEFAULT_ORGANIZATION_ID
    end

    # Required for Gitlab::VisibilityLevel module
    def visibility_level_field
      :visibility_level
    end

    def organization_detail
      super.presence || build_organization_detail
    end

    def default?
      self.class.default?(id)
    end

    def to_param
      path
    end

    def owner_user_ids
      # rubocop:disable Database/AvoidUsingPluckWithoutLimit -- few owners, and not used with IN clause
      organization_users.owners.pluck(:user_id)
      # rubocop:enable Database/AvoidUsingPluckWithoutLimit
    end
    strong_memoize_attr :owner_user_ids

    def user?(user)
      organization_users.exists?(user: user)
    end

    def owner?(user)
      organization_users.owners.exists?(user: user)
    end

    def add_owner(user)
      organization_users.owners.create(user: user)
    end

    def web_url(only_path: nil)
      Gitlab::UrlBuilder.build(self, only_path: only_path)
    end

    # For example:
    # scoped path   - /o/my-org/my-group/my-project
    # unscoped path - /my-group/my-project
    def scoped_paths?
      Feature.enabled?(:organization_scoped_paths, self) && !default?
    end

    def inspect
      "#<#{self.class.name} id:#{id} path:#{path}>"
    end

    # Root path in the context of this organization instance.
    def root_path
      return organization_root_path(self) if scoped_paths?

      unscoped_root_path
    end

    # Deprecated, use root_path instead.
    # Will be removed in future commit.
    def full_path
      return '' unless scoped_paths?

      "/o/#{path}"
    end

    private

    # The visibility must be broader than the visibility of any contained root groups.
    def check_visibility_level
      max_group_level = root_groups.maximum(:visibility_level)
      return unless max_group_level

      return if visibility_level >= max_group_level

      errors.add(:visibility_level, _("can not be more restrictive than group visibility levels"))
    end

    # The 'o' path is reserved as it's used for routing organization resources
    # Example: /o/:organization_path
    def check_organization_reserved_name
      return if default?
      return unless Namespace.filter_by_path('o').top_level.exists?

      errors.add(
        :base,
        _('Cannot create organization. The `o` namespace is a reserved path. ' \
          'Please rename the group or user before creating an organization.')
      )
    end

    def check_if_default_organization
      return unless default?

      raise ActiveRecord::RecordNotDestroyed, _('Cannot delete the default organization')
    end
  end
end

::Organizations::Organization.prepend_mod_with('Organizations::Organization')
