# frozen_string_literal: true

require_dependency 'gitlab/auth/devise/strategies/combined_two_factor_authenticatable'

# Use this hook to configure devise mailer, warden hooks and so forth. The first
# four configuration values can also be set straight in your models.
Devise.setup do |config|
  config.warden do |manager|
    user_scoped_strategies = manager.default_strategies(scope: :user)
    user_scoped_strategies.delete :two_factor_backupable
    user_scoped_strategies.delete :two_factor_authenticatable
    user_scoped_strategies.unshift :combined_two_factor_authenticatable
  end

  # This is the default. This makes it explicit that Devise loads routes
  # before eager loading. Disabling this seems to cause an error loading
  # grape-entity `expose` for some reason.
  config.reload_routes = true

  # ==> Mailer Configuration
  # Configure the class responsible to send e-mails.
  config.mailer = "DeviseMailer"

  # ==> ORM configuration
  # Load and configure the ORM. Supports :active_record (default) and
  # :mongoid (bson_ext recommended) by default. Other ORMs may be
  # available as additional gems.
  require 'devise/orm/active_record'

  # ==> Configuration for any authentication mechanism
  # Configure which keys are used when authenticating a user. The default is
  # just :email. You can configure it to use [:username, :subdomain], so for
  # authenticating a user, both parameters are required. Remember that those
  # parameters are used only when authenticating and not when retrieving from
  # session. If you need permissions, you should implement that in a before filter.
  # You can also supply a hash where the value is a boolean determining whether
  # or not authentication should be aborted when the value is not present.
  config.authentication_keys = [:login]

  # Configure parameters from the request object used for authentication. Each entry
  # given should be a request method and it will automatically be passed to the
  # find_for_authentication method and considered in your model lookup. For instance,
  # if you set :request_keys to [:subdomain], :subdomain will be used on authentication.
  # The same considerations mentioned for authentication_keys also apply to request_keys.
  # config.request_keys = []

  # Configure which authentication keys should be case-insensitive.
  # These keys will be downcased upon creating or modifying a user and when used
  # to authenticate or find a user. Default is :email.
  config.case_insensitive_keys = [:email]

  # Configure which authentication keys should have whitespace stripped.
  # These keys will have whitespace before and after removed upon creating or
  # modifying a user and when used to authenticate or find a user. Default is :email.
  config.strip_whitespace_keys = [:email]

  # Tell if authentication through request.params is enabled. True by default.
  # config.params_authenticatable = true

  # Tell if authentication through HTTP Basic Auth is enabled. False by default.
  # config.http_authenticatable = false

  # If http headers should be returned for AJAX requests. True by default.
  # config.http_authenticatable_on_xhr = true

  # The realm used in Http Basic Authentication. "Application" by default.
  # config.http_authentication_realm = "Application"

  config.reconfirmable = true

  # It will change confirmation, password recovery and other workflows
  # to behave the same regardless if the e-mail provided was right or wrong.
  # Does not affect registerable.
  config.paranoid = true

  # ==> Configuration for :database_authenticatable
  # For bcrypt, this is the cost for hashing the password and defaults to 10. If
  # using other encryptors, it sets how many times you want the password re-encrypted.
  #
  # Limiting the stretches to just one in testing will increase the performance of
  # your test suite dramatically. However, it is STRONGLY RECOMMENDED to not use
  # a value less than 10 in other environments.
  config.stretches = Rails.env.test? ? 1 : 10

  # Set up a pepper to generate the encrypted password.
  # config.pepper = "2ef62d549c4ff98a5d3e0ba211e72cff592060247e3bbbb9f499af1222f876f53d39b39b823132affb32858168c79c1d7741d26499901b63c6030a42129924ef"

  # ==> Configuration for :confirmable
  # The time you want to give a user to confirm their account. During this time
  # they will be able to access your application without confirming. Default is 0.days
  # When allow_unconfirmed_access_for is zero, the user won't be able to sign in without confirming.
  # You can use this to let your user access some features of your application
  # without confirming the account, but blocking it after a certain period
  # (e.g. 3 days).
  config.allow_unconfirmed_access_for = 3.days

  # A period that the user is allowed to confirm their account before their
  # token becomes invalid. For example, if set to 1.day, the user can confirm
  # their account within 1 days after the mail was sent, but on the second day
  # their account can't be confirmed with the token any more.
  # Default is nil, meaning there is no restriction on how long a user can take
  # before confirming their account.
  config.confirm_within = 1.day

  # Defines which key will be used when confirming an account
  # config.confirmation_keys = [ :email ]

  # ==> Configuration for :rememberable
  # The time the user will be remembered without asking for credentials again.
  # config.remember_for = 2.weeks

  # If true, a valid remember token can be re-used between multiple browsers.
  # config.remember_across_browsers = true

  # If true, extends the user's remember period when remembered via cookie.
  config.extend_remember_period = true

  # Options to be passed to the created cookie. For instance, you can set
  # secure: true in order to force SSL only cookies.
  # config.cookie_options = {}

  # When set to false, does not sign a user in automatically after their password is
  # changed. Defaults to true, so a user is signed in automatically after a password
  # is changed.
  config.sign_in_after_change_password = false

  # Send a notification email when the user's password is changed
  config.send_password_change_notification = true

  # Send a notification email when the user's email is changed
  config.send_email_changed_notification = true

  # ==> Configuration for :validatable
  # Range for password length. Default is 6..128.
  config.password_length = 8..128

  # Email regex used to validate email formats. It simply asserts that
  # an one (and only one) @ exists in the given string. This is mainly
  # to give user feedback and not to assert the e-mail validity.
  # config.email_regexp = /\A[^@]+@[^@]+\z/

  # ==> Configuration for :timeoutable
  # The time you want to timeout the user session without activity. After this
  # time the user will be asked for credentials again. Default is 30 minutes.
  # config.timeout_in = 30.minutes

  # ==> Configuration for :lockable
  # Defines which strategy will be used to lock an account.
  # :failed_attempts = Locks an account after a number of failed attempts to sign in.
  # :none            = No lock strategy. You should handle locking by yourself.
  config.lock_strategy = :failed_attempts

  # Defines which key will be used when locking and unlocking an account
  config.unlock_keys = [:email]

  # Defines which strategy will be used to unlock an account.
  # :email = Sends an unlock link to the user email
  # :time  = Re-enables login after a certain amount of time (see :unlock_in below)
  # :both  = Enables both strategies
  # :none  = No unlock strategy. You should handle unlocking by yourself.
  config.unlock_strategy = :both

  ActiveSupport.on_load(:gitlab_db_load_balancer) do
    # Number of authentication tries before locking an account if lock_strategy
    # is failed attempts.
    config.maximum_attempts = if Gitlab::CurrentSettings.max_login_attempts_column_exists?
                                (Gitlab::CurrentSettings.max_login_attempts || 10)
                              else
                                10
                              end

    # Time interval to unlock the account if :time is enabled as unlock_strategy.
    config.unlock_in = if Gitlab::CurrentSettings.failed_login_attempts_unlock_period_in_minutes_column_exists?
                         (Gitlab::CurrentSettings.failed_login_attempts_unlock_period_in_minutes || 10).minutes
                       else
                         10.minutes
                       end
  end

  # ==> Configuration for :recoverable
  #
  # Defines which key will be used when recovering the password for an account
  # config.reset_password_keys = [ :email ]

  # Time interval you can reset your password with a reset password key.
  # Don't put a too small interval or your users won't have the time to
  # change their passwords.
  # When someone else invites you to GitLab this time is also used so it should be pretty long.
  config.reset_password_within = 2.days

  # When set to false, does not sign a user in automatically after their password is
  # reset. Defaults to true, so a user is signed in automatically after a reset.
  config.sign_in_after_reset_password = false

  # Authentication through token does not store user in session and needs
  # to be supplied on each request. Useful if you are using the token as API token.
  config.skip_session_storage << :token_auth

  # ==> Scopes configuration
  # Turn scoped views on. Before rendering "sessions/new", it will first check for
  # "users/sessions/new". It's turned off by default because it's slower if you
  # are using only default views.
  # config.scoped_views = false

  # Configure the default scope given to Warden. By default it's the first
  # devise role declared in your routes (usually :user).
  config.default_scope = :user # now have an :email scope as well, so set the default

  # Configure sign_out behavior.
  # Sign_out action can be scoped (i.e. /users/sign_out affects only :user scope).
  # The default is true, which means any logout action will sign out all active scopes.
  # config.sign_out_all_scopes = true

  # ==> Navigation configuration
  # Lists the formats that should be treated as navigational. Formats like
  # :html, should redirect to the sign in page when the user does not have
  # access, but formats like :xml or :json, should return 401.
  #
  # If you have any extra navigational formats, like :iphone or :mobile, you
  # should add them to the navigational formats lists.
  #
  # The :"*/*" and "*/*" formats below is required to match Internet
  # Explorer requests.
  config.navigational_formats = [:"*/*", "*/*", :html, :zip]

  # The default HTTP method used to sign out a resource. Default is :delete.
  config.sign_out_via = :post

  # ==> OmniAuth
  # To configure a new OmniAuth provider copy and edit omniauth.rb.sample
  # selecting the provider you require.
  # Check the wiki for more information on setting up on your models

  # ==> Warden configuration
  # If you want to use other strategies, that are not supported by Devise, or
  # change the failure app, you can configure them inside the config.warden block.
  #
  config.warden do |manager|
    manager.failure_app = Gitlab::DeviseFailure
  end

  if Gitlab::Auth::Ldap::Config.enabled?
    Gitlab::Auth::Ldap::Config.available_providers.each do |provider|
      ldap_config = Gitlab::Auth::Ldap::Config.new(provider)
      config.omniauth(provider, ldap_config.omniauth_options)
    end
  end

  if Gitlab::Auth.omniauth_enabled?
    Gitlab::OmniauthInitializer.new(config).execute(Gitlab.config.omniauth.providers)
  end
end
