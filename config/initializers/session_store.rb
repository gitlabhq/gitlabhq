# Be sure to restart your server when you modify this file.

Gitlab::Application.config.session_store :cookie_store, key: '_gitlab_session',
                                                      secure: Gitlab::Application.config.force_ssl,
                                                      httponly: true

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rails generate session_migration")
# Gitlab::Application.config.session_store :active_record_store
