# GIT over HTTP
require Rails.root.join("lib", "gitlab", "backend", "grack_auth")

# GIT over SSH
require Rails.root.join("lib", "gitlab", "backend", "shell")

# GitLab shell adapter
require Rails.root.join("lib", "gitlab", "backend", "shell_adapter")

# Gitlab Git repos path
Gitlab::Git::Repository.repos_path = Gitlab.config.gitlab_shell.repos_path
