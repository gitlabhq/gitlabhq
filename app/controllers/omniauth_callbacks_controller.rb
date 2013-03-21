class OmniauthCallbacksController < Devise::OmniauthCallbacksController
  Gitlab.config.omniauth.providers.each_pair do |provider, args|
    if args['enabled']
      define_method provider do
        handle_omniauth
      end
    end
  end

  # Extend the standard message generation to accept our custom exception
  def failure_message
    exception = env["omniauth.error"]
    error   = exception.error_reason if exception.respond_to?(:error_reason)
    error ||= exception.error        if exception.respond_to?(:error)
    error ||= exception.message      if exception.respond_to?(:message)
    error ||= env["omniauth.error.type"].to_s
    error.to_s.humanize if error
  end

  private

  def handle_omniauth
    oauth = request.env['omniauth.auth']
    provider, uid = oauth['provider'], oauth['uid']

    if current_user
      # Change a logged-in user's authentication method:
      current_user.extern_uid = uid
      current_user.provider = provider
      current_user.save
      redirect_to profile_path
    else
      begin
        @user = User.find_or_new_for_omniauth(oauth)
      rescue => exception
        omniauth_fail!(exception)
      end

      if @user
        sign_in_and_redirect @user
      else
        flash[:notice] = "There's no such user!"
        redirect_to new_user_session_path
      end
    end
  end

  def omniauth_fail!(exception)
    error = "Internal application error occurred".to_sym
    env['omniauth.error'] = nil
    env['omniauth.error.type'] = error
    env['omniauth.error.strategy'] = env['omniauth.strategy']

    log_exception(exception)

    OmniAuth.config.on_failure.call(env)
  end

  # FIXME: this is copy from app/controllers/application_controller.rb
  def log_exception(exception)
    application_trace = ActionDispatch::ExceptionWrapper.new(env, exception).application_trace
    application_trace.map!{ |t| "  #{t}\n" }
    logger.error "\n#{exception.class.name} (#{exception.message}):\n#{application_trace.join}"
  end
end
