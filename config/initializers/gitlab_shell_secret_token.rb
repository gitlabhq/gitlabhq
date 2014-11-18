# Be sure to restart your server when you modify this file.

require 'securerandom'

# Your secret key for verifying the gitlab_shell.


secret_file = Rails.root.join('.gitlab_shell_secret')
gitlab_shell_symlink = File.join(Gitlab.config.gitlab_shell.path, '.gitlab_shell_secret')

unless File.exist? secret_file
  # Generate a new token of 16 random hexadecimal characters and store it in secret_file.
  token = SecureRandom.hex(16)
  File.write(secret_file, token)
end

if File.exist?(Gitlab.config.gitlab_shell.path) && !File.exist?(gitlab_shell_symlink)
  FileUtils.symlink(secret_file, gitlab_shell_symlink)
end