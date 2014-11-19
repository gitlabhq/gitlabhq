require 'shellwords'
path = File.join(Settings.gitlab_shell['hooks_path'], '.env')
key = 'PATH'
content = "export #{key}=#{Shellwords.escape(ENV[key])}\n"
File.write(path, content)
