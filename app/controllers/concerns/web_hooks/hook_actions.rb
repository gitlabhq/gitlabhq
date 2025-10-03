# frozen_string_literal: true

module WebHooks
  module HookActions
    extend ActiveSupport::Concern
    include HookExecutionNotice

    included do
      attr_writer :hooks, :hook

      before_action :hook_logs, only: :edit
      feature_category :webhooks
    end

    def index
      self.hooks = relation.select(&:persisted?)
      self.hook = relation.new
    end

    def create
      organization = Current.organization

      result = WebHooks::CreateService.new(current_user).execute(hook_params, relation, organization)

      if result.success?
        flash[:notice] = _('Webhook created')
      else
        self.hooks = relation.select(&:persisted?)
        flash[:alert] = result.message
      end

      redirect_to action: :index
    end

    def update
      if hook.update(hook_params)
        flash[:notice] = _('Webhook updated')
        redirect_to action: :edit
      else
        if hook.errors[:custom_headers].present?
          flash.now[:alert] =
            format(_("Custom headers validation failed: %{errors}"), errors: hook.errors[:custom_headers].join(', '))
          # clean invalid headers before re-rendering
          hook.custom_headers = filter_valid_headers(hook.custom_headers)
        elsif hook.errors.any?
          flash.now[:alert] =
            format(_("Please fix the following errors: %{errors}"), errors: hook.errors.full_messages.join(', '))
        end

        render 'edit'
      end
    end

    def destroy
      destroy_hook(hook)

      redirect_to action: :index, status: :found
    end

    def edit
      redirect_to(action: :index) unless hook
    end

    private

    def filter_valid_headers(headers)
      return {} if headers.blank?

      valid_headers = {}
      headers.each do |key, value|
        temp_hook = hook.class.new(custom_headers: { key => value })
        temp_hook.validate

        valid_headers[key] = value if temp_hook.errors[:custom_headers].empty?
      end
      valid_headers
    end

    def hook_params
      permitted = hook_param_names + trigger_values
      permitted << { url_variables: [:key, :value], custom_headers: [:key, :value] }

      ps = params.require(:hook).permit(*permitted).to_h

      ps.delete(:token) if action_name == 'update' && ps[:token] == WebHook::SECRET_MASK

      ps[:url_variables] = ps[:url_variables].to_h { [_1[:key], _1[:value].presence] } if ps.key?(:url_variables)
      ps[:custom_headers] = ps[:custom_headers].to_h { [_1[:key], hook_value_from_param_or_db(_1[:key], _1[:value])] }

      if action_name == 'update' && ps.key?(:url_variables)
        supplied = ps[:url_variables]
        ps[:url_variables] = hook.url_variables.merge(supplied).compact
      end

      ps
    end

    def hook_param_names
      %i[enable_ssl_verification name description token url push_events_branch_filter branch_filter_strategy
        custom_webhook_template]
    end

    def destroy_hook(hook)
      result = WebHooks::DestroyService.new(current_user).execute(hook)

      if result[:status] == :success
        flash[:notice] = result[:async] ? _('Webhook scheduled for deletion') : _('Webhook deleted')
      else
        flash[:alert] = result[:message]
      end
    end

    def hook_logs
      @hook_logs ||= hook.web_hook_logs.recent.page(pagination_params[:page]).without_count
    end

    def hook_value_from_param_or_db(key, value)
      if value == WebHook::SECRET_MASK && hook.custom_headers.key?(key)
        hook.custom_headers[key]
      else
        value
      end
    end
  end
end
