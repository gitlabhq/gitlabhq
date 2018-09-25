# Sidekiq debugging

## Log arguments to Sidekiq jobs

If you want to see what arguments are being passed to Sidekiq jobs you can set
the `SIDEKIQ_LOG_ARGUMENTS` [environment variable](https://docs.gitlab.com/omnibus/settings/environment-variables.html) to `1` (true).

Example:

```
gitlab_rails['env'] = {"SIDEKIQ_LOG_ARGUMENTS" => "1"}
```

Please note: It is not recommend to enable this setting in production because some 
Sidekiq jobs (such as sending a password reset email) take secret arguments (for
example the password reset token).