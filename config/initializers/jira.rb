# Treats JIRA DVCS user agent requests in order to be successfully handled
# by our API.
Rails.application.config.middleware.use(Gitlab::Jira::Middleware)
