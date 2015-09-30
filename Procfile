web: bundle exec unicorn_rails -p ${PORT:="3000"} -E ${RAILS_ENV:="development"} -c ${UNICORN_CONFIG:="config/unicorn.rb"}
worker: bundle exec sidekiq -q post_receive -q mailer -q archive_repo -q system_hook -q project_web_hook -q gitlab_shell -q incoming_email -q runner -q common -q default
# mail_room: bundle exec mail_room -q -c config/mail_room.yml
