# frozen_string_literal: true

module Terraform
  class RemoteStateHandler < BaseService
    include Gitlab::OptimisticLocking

    StateLockedError = Class.new(StandardError)

    # rubocop: disable CodeReuse/ActiveRecord
    def find_with_lock
      raise ArgumentError unless params[:name].present?

      state = Terraform::State.find_by(project: project, name: params[:name])
      raise ActiveRecord::RecordNotFound.new("Couldn't find state") unless state

      retry_optimistic_lock(state) { |state| yield state } if state && block_given?
      state
    end
    # rubocop: enable CodeReuse/ActiveRecord

    def create_or_find!
      raise ArgumentError unless params[:name].present?

      Terraform::State.create_or_find_by(project: project, name: params[:name])
    end

    def handle_with_lock
      retrieve_with_lock do |state|
        raise StateLockedError unless lock_matches?(state)

        yield state if block_given?

        state.save! unless state.destroyed?
      end
    end

    def lock!
      raise ArgumentError if params[:lock_id].blank?

      retrieve_with_lock do |state|
        raise StateLockedError if state.locked?

        state.lock_xid = params[:lock_id]
        state.locked_by_user = current_user
        state.locked_at = Time.now

        state.save!
      end
    end

    def unlock!
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

    def retrieve_with_lock
      create_or_find!.tap { |state| retry_optimistic_lock(state) { |state| yield state } }
    end

    def lock_matches?(state)
      return true if state.lock_xid.nil? && params[:lock_id].nil?

      ActiveSupport::SecurityUtils
        .secure_compare(state.lock_xid.to_s, params[:lock_id].to_s)
    end
  end
end
