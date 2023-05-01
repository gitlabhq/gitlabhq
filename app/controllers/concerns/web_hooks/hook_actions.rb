# frozen_string_literal: true

module WebHooks
  module HookActions
    extend ActiveSupport::Concern
    include HookExecutionNotice

    included do
      attr_writer :hooks, :hook

      before_action :hook_logs, only: :edit
    end

    def index
      self.hooks = relation.select(&:persisted?)
      self.hook = relation.new
    end

    def create
      self.hook = relation.new(hook_params)
      hook.save

      if hook.valid?
        flash[:notice] = _('Webhook was created')
      else
        self.hooks = relation.select(&:persisted?)
        flash[:alert] = hook.errors.full_messages.to_sentence.html_safe
      end

      redirect_to action: :index
    end

    def update
      if hook.update(hook_params)
        flash[:notice] = _('Webhook was updated')
        redirect_to action: :edit
      else
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

    def hook_params
      permitted = hook_param_names + trigger_values
      permitted << { url_variables: [:key, :value] }

      ps = params.require(:hook).permit(*permitted).to_h

      ps.delete(:token) if action_name == 'update' && ps[:token] == WebHook::SECRET_MASK

      ps[:url_variables] = ps[:url_variables].to_h { [_1[:key], _1[:value].presence] } if ps.key?(:url_variables)

      if action_name == 'update' && ps.key?(:url_variables)
        supplied = ps[:url_variables]
        ps[:url_variables] = hook.url_variables.merge(supplied).compact
      end

      ps
    end

    def hook_param_names
      %i[enable_ssl_verification token url push_events_branch_filter branch_filter_strategy]
    end

    def destroy_hook(hook)
      result = WebHooks::DestroyService.new(current_user).execute(hook)

      if result[:status] == :success
        flash[:notice] = result[:async] ? _('Webhook was scheduled for deletion') : _('Webhook was deleted')
      else
        flash[:alert] = result[:message]
      end
    end

    def hook_logs
      @hook_logs ||= hook.web_hook_logs.recent.page(params[:page]).without_count
    end
  end
end
