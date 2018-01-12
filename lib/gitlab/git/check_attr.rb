module Gitlab
  module Git
    class CheckAttr
      include Gitlab::Git::Popen

      def initialize(repository, ref)
        @path_to_repo = repository.path_to_repo
        popen(command_args('read-tree', '--reset', '-i', ref), nil, env)
      end

      def attributes(file_path)
        Attributes.new(self, file_path)
      end

      def execute(file_path, attr_key='--all')
        output, status = popen(command_args('check-attr', '--cached', attr_key, file_path), nil, env)

        output
      end

      private

      class Attributes
        def initialize(check_attr, file_path)
          @check_attr = check_attr
          @file_path = file_path
        end

        def [](attr_key)
          output = @check_attr.execute(@file_path, attr_key)
          output.each_line.map{|l| l.chomp.split(': ').drop(1)}.to_h[attr_key]
        end
      end

      def env
        # Gitlab::Git::Env.to_env_hash
        {'GIT_INDEX_FILE' => '/tmp/tmp-index'}
      end

      def command_args(command, *params)
        [Gitlab.config.git.bin_path, "--git-dir=#{@path_to_repo}", command, *params]
      end
    end
  end
end