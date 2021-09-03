# frozen_string_literal: true

module Terraform
  class RemoteStateHandler < BaseService
    include Gitlab::OptimisticLocking

    StateLockedError = Class.new(StandardError)
    UnauthorizedError = Class.new(StandardError)

    def find_with_lock
      retrieve_with_lock(find_only: true) do |state|
        yield state if block_given?
      end
    end

    def handle_with_lock
      raise UnauthorizedError unless can_modify_state?

      retrieve_with_lock do |state|
        raise StateLockedError unless lock_matches?(state)

        yield state if block_given?

        state.save! unless state.destroyed?
      end

      nil
    end

    def lock!
      raise ArgumentError if params[:lock_id].blank?
      raise UnauthorizedError unless can_modify_state?

      retrieve_with_lock do |state|
        raise StateLockedError if state.locked?

        state.lock_xid = params[:lock_id]
        state.locked_by_user = current_user
        state.locked_at = Time.current

        state.save!
      end
    end

    def unlock!
      raise UnauthorizedError unless can_modify_state?

      retrieve_with_lock do |state|
        # force-unlock does not pass ID, so we ignore it if it is missing
        raise StateLockedError unless params[:lock_id].nil? || lock_matches?(state)

        state.lock_xid = nil
        state.locked_by_user = nil
        state.locked_at = nil

        state.save!
      end
    end

    private

    def retrieve_with_lock(find_only: false)
      create_or_find!(find_only: find_only).tap { |state| retry_optimistic_lock(state, name: 'terraform_remote_state_handler_retrieve') { |state| yield state } }
    end

    def create_or_find!(find_only:)
      raise ArgumentError unless params[:name].present?

      find_params = { project: project, name: params[:name] }

      return find_state!(find_params) if find_only

      state = Terraform::State.create_or_find_by(find_params)

      # https://github.com/rails/rails/issues/36027
      return state unless state.errors.of_kind? :name, :taken

      find_state(find_params)
    end

    def lock_matches?(state)
      return true if state.lock_xid.nil? && params[:lock_id].nil?

      ActiveSupport::SecurityUtils
        .secure_compare(state.lock_xid.to_s, params[:lock_id].to_s)
    end

    def can_modify_state?
      current_user.can?(:admin_terraform_state, project)
    end

    def find_state(find_params)
      Terraform::State.find_by(find_params) # rubocop: disable CodeReuse/ActiveRecord
    end

    def find_state!(find_params)
      find_state(find_params) || raise(ActiveRecord::RecordNotFound, "Couldn't find state")
    end
  end
end
