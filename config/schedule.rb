# Use this file to easily define all of your cron jobs.
#
# If you make changes to this file, please create also an issue on
# https://gitlab.com/gitlab-org/omnibus-gitlab/issues . This is necessary
# because the omnibus packages manage cron jobs using Chef instead of Whenever.
every 1.hour do
  rake "ci:schedule_builds"
end
