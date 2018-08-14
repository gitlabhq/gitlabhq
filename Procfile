# For DEVELOPMENT only. Production uses Runit in
# https://gitlab.com/gitlab-org/omnibus-gitlab or the init scripts in
# lib/support/init.d, which call scripts in bin/ .
#
web: RAILS_ENV=development bin/web start_foreground
worker: RAILS_ENV=development bin/background_jobs start_foreground
