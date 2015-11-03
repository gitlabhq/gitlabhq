# For DEVELOPMENT only. Production uses Runit in
# https://gitlab.com/gitlab-org/omnibus-gitlab or the init scripts in
# lib/support/init.d, which call scripts in bin/ .
#
web: bundle exec unicorn_rails -p ${PORT:="3000"} -E ${RAILS_ENV:="development"} -c ${UNICORN_CONFIG:="config/unicorn.rb"}
worker: bundle exec sidekiq -q post_receive -q mailers -q archive_repo -q system_hook -q project_web_hook -q gitlab_shell -q incoming_email -q runner -q common -q default -q pages
# mail_room: bundle exec mail_room -q -c config/mail_room.yml
