# Remove this in 9.0, this is just to allow a post-deployment migration to
# rename the service. See https://gitlab.com/gitlab-org/gitlab-ce/issues/25855
class SlackService < SlackNotificationService
end
