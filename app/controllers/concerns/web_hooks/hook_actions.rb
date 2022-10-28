# frozen_string_literal: true

module WebHooks
  module HookActions
    extend ActiveSupport::Concern
    include HookExecutionNotice

    included do
      attr_writer :hooks, :hook
    end

    def index
      self.hooks = relation.select(&:persisted?)
      self.hook = relation.new
    end

    def create
      self.hook = relation.new(hook_params)
      hook.save

      unless hook.valid?
        self.hooks = relation.select(&:persisted?)
        flash[:alert] = hook.errors.full_messages.to_sentence.html_safe
      end

      redirect_to action: :index
    end

    def update
      if hook.update(hook_params)
        flash[:notice] = _('Hook was successfully updated.')
        redirect_to action: :index
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
      param_names = %i[enable_ssl_verification token url push_events_branch_filter]
      param_names.push(:branch_filter_strategy) if Feature.enabled?(:enhanced_webhook_support_regex)
      param_names
    end

    def destroy_hook(hook)
      result = WebHooks::DestroyService.new(current_user).execute(hook)

      if result[:status] == :success
        flash[:notice] =
          if result[:async]
            format(_("%{hook_type} was scheduled for deletion"), hook_type: hook.model_name.human)
          else
            format(_("%{hook_type} was deleted"), hook_type: hook.model_name.human)
          end
      else
        flash[:alert] = result[:message]
      end
    end
  end
end
