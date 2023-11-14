# frozen_string_literal: true

namespace :gitlab do
  namespace :redis do
    namespace :secret do
      desc "GitLab | Redis | Secret | Show Redis secret"
      task :show, [:instance_name] => [:environment] do |_t, args|
        Gitlab::EncryptedRedisCommand.show(args: args)
      end

      desc "GitLab | Redis | Secret | Edit Redis secret"
      task :edit, [:instance_name] => [:environment] do |_t, args|
        Gitlab::EncryptedRedisCommand.edit(args: args)
      end

      desc "GitLab | Redis | Secret | Write Redis secret"
      task :write, [:instance_name] => [:environment] do |_t, args|
        content = $stdin.tty? ? $stdin.gets : $stdin.read
        Gitlab::EncryptedRedisCommand.write(content, args: args)
      end
    end
  end
end
