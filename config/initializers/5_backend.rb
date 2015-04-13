# GIT over HTTP
require Rails.root.join("lib", "gitlab", "backend", "grack_auth")

# GIT over SSH
require Rails.root.join("lib", "gitlab", "backend", "shell")

# GitLab shell adapter
require Rails.root.join("lib", "gitlab", "backend", "shell_adapter")

required_version = Gitlab::VersionInfo.parse(Gitlab::Shell.version_required)
current_version = Gitlab::VersionInfo.parse(Gitlab::Shell.new.version)

unless current_version.valid? && required_version <= current_version
  warn "WARNING: This version of GitLab depends on gitlab-shell #{required_version}, but you're running #{current_version}. Please update gitlab-shell."
end
