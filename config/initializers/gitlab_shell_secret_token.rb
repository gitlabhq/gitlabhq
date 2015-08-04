# Be sure to restart your server when you modify this file.

require 'securerandom'

# Your secret key for verifying the gitlab_shell.


secret_file = Gitlab.config.gitlab_shell.secret_file

unless File.exist? secret_file
  # Generate a new token of 16 random hexadecimal characters and store it in secret_file.
  token = SecureRandom.hex(16)
  File.write(secret_file, token)
end

link_path = File.join(Gitlab.config.gitlab_shell.path, '.gitlab_shell_secret')
if File.exist?(Gitlab.config.gitlab_shell.path) && !File.exist?(link_path)
  FileUtils.symlink(secret_file, link_path)
end
