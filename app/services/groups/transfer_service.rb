module Groups
  class TransferService < Groups::BaseService
    ERROR_MESSAGES = {
      database_not_supported: 'Database is not supported.',
      namespace_with_same_path: 'The parent group already has a subgroup with the same path.',
      group_is_already_root: 'Group is already a root group.',
      same_parent_as_current: 'Group is already associated to the parent group.',
      invalid_policies: "You don't have enough permissions."
    }.freeze

    TransferError = Class.new(StandardError)

    attr_reader :error

    def initialize(group, user, params = {})
      super
      @error = nil
    end

    def execute(new_parent_group)
      @new_parent_group = new_parent_group
      ensure_allowed_transfer
      proceed_to_transfer

    rescue TransferError, ActiveRecord::RecordInvalid, Gitlab::UpdatePathError => e
      @group.errors.clear
      @error = "Transfer failed: " + e.message
      false
    end

    private

    def proceed_to_transfer
      Group.transaction do
        update_group_attributes
      end
    end

    def ensure_allowed_transfer
      raise_transfer_error(:group_is_already_root) if group_is_already_root?
      raise_transfer_error(:database_not_supported) unless Group.supports_nested_groups?
      raise_transfer_error(:same_parent_as_current) if same_parent?
      raise_transfer_error(:invalid_policies) unless valid_policies?
      raise_transfer_error(:namespace_with_same_path) if namespace_with_same_path?
    end

    def group_is_already_root?
      !@new_parent_group && !@group.has_parent?
    end

    def same_parent?
      @new_parent_group && @new_parent_group.id == @group.parent_id
    end

    def valid_policies?
      return false unless can?(current_user, :admin_group, @group)

      if @new_parent_group
        can?(current_user, :create_subgroup, @new_parent_group)
      else
        can?(current_user, :create_group)
      end
    end

    def namespace_with_same_path?
      Namespace.exists?(path: @group.path, parent: @new_parent_group)
    end

    def update_group_attributes
      if @new_parent_group && @new_parent_group.visibility_level < @group.visibility_level
        update_children_and_projects_visibility
        @group.visibility_level = @new_parent_group.visibility_level
      end

      @group.parent = @new_parent_group
      @group.save!
    end

    def update_children_and_projects_visibility
      descendants = @group.descendants.where("visibility_level > ?", @new_parent_group.visibility_level)

      Group
        .where(id: descendants.select(:id))
        .update_all(visibility_level: @new_parent_group.visibility_level)

      @group
        .all_projects
        .where("visibility_level > ?", @new_parent_group.visibility_level)
        .update_all(visibility_level: @new_parent_group.visibility_level)
    end

    def raise_transfer_error(message)
      raise TransferError, ERROR_MESSAGES[message]
    end
  end
end
