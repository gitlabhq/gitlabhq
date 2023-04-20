# frozen_string_literal: true

module Ci
  class RunnersFinder < UnionFinder
    include Gitlab::Allowable

    ALLOWED_SORTS = %w[contacted_asc contacted_desc created_at_asc created_at_desc created_date token_expires_at_asc token_expires_at_desc].freeze
    DEFAULT_SORT = 'created_at_desc'

    def initialize(current_user:, params:)
      @params = params
      @group = params.delete(:group)
      @project = params.delete(:project)
      @current_user = current_user
    end

    def execute
      search!
      filter_by_active!
      filter_by_status!
      filter_by_upgrade_status!
      filter_by_runner_type!
      filter_by_tag_list!
      sort!
      request_tag_list!

      @runners

    rescue Gitlab::Access::AccessDeniedError
      Ci::Runner.none
    end

    def sort_key
      ALLOWED_SORTS.include?(@params[:sort]) ? @params[:sort] : DEFAULT_SORT
    end

    private

    def search!
      if @project
        project_runners
      elsif @group
        group_runners
      else
        all_runners
      end

      @runners = @runners.search(@params[:search]) if @params[:search].present?
    end

    def all_runners
      raise Gitlab::Access::AccessDeniedError unless @current_user&.can_admin_all_resources?

      @runners = Ci::Runner.all
    end

    def group_runners
      raise Gitlab::Access::AccessDeniedError unless can?(@current_user, :read_group_runners, @group)

      @runners = case @params[:membership]
                 when :direct
                   Ci::Runner.belonging_to_group(@group.id)
                 when :descendants, nil
                   Ci::Runner.belonging_to_group_or_project_descendants(@group.id)
                 when :all_available
                   unless can?(@current_user, :read_group_all_available_runners, @group)
                     raise Gitlab::Access::AccessDeniedError
                   end

                   Ci::Runner.usable_from_scope(@group)
                 else
                   raise ArgumentError, 'Invalid membership filter'
                 end
    end

    def project_runners
      raise Gitlab::Access::AccessDeniedError unless can?(@current_user, :read_project_runners, @project)

      @runners = ::Ci::Runner.owned_or_instance_wide(@project.id)
    end

    def filter_by_active!
      @runners = @runners.active(@params[:active]) if @params.include?(:active)
    end

    def filter_by_status!
      filter_by!(:status_status, Ci::Runner::AVAILABLE_STATUSES)
    end

    def filter_by_upgrade_status!
      upgrade_status = @params[:upgrade_status]

      return unless upgrade_status

      unless Ci::RunnerVersion.statuses.key?(upgrade_status)
        raise ArgumentError, "Invalid upgrade status value '#{upgrade_status}'"
      end

      @runners = @runners.with_upgrade_status(upgrade_status)
    end

    def filter_by_runner_type!
      filter_by!(:type_type, Ci::Runner::AVAILABLE_TYPES)
    end

    def filter_by_tag_list!
      tag_list = @params[:tag_name].presence

      if tag_list
        @runners = @runners.tagged_with(tag_list)
      end
    end

    def sort!
      @runners = @runners.order_by(sort_key)
    end

    def request_tag_list!
      @runners = @runners.with_tags if !@params[:preload].present? || @params.dig(:preload, :tag_name)
    end

    def filter_by!(scope_name, available_scopes)
      scope = @params[scope_name]

      if scope.present? && available_scopes.include?(scope)
        @runners = @runners.public_send(scope) # rubocop:disable GitlabSecurity/PublicSend
      end
    end
  end
end
