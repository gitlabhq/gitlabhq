# Sidekiq debugging

## Log arguments to Sidekiq jobs

If you want to see what arguments are being passed to Sidekiq jobs you can set
the SIDEKIQ_LOG_ARGUMENTS environment variable.

```
SIDEKIQ_LOG_ARGUMENTS=1 bundle exec foreman start
```

It is not recommend to enable this setting in production because some Sidekiq
jobs (such as sending a password reset email) take secret arguments (for
example the password reset token).
