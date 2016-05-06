module Gitlab
  module ImportExport
    module CommandLineUtil
      def tar_czf(archive:, dir:)
        tar_with_options(archive: archive, dir: dir, options: 'czf')
      end

      def untar_zxf(archive:, dir:)
        untar_with_options(archive: archive, dir: dir, options: 'zxf')
      end

      def git_bundle(git_bin_path: Gitlab.config.git.bin_path, repo_path:, bundle_path:)
        execute(%W(#{git_bin_path} --git-dir=#{repo_path} bundle create #{bundle_path} --all))
      end

      def git_unbundle(git_bin_path: Gitlab.config.git.bin_path, repo_path:, bundle_path:)
        execute(%W(#{git_bin_path} clone --bare #{bundle_path} #{repo_path}))
      end

      private

      def git_unbundle(git_bin_path: Gitlab.config.git.bin_path, repo_path:, bundle_path:)
        cmd = %W(#{git_bin_path} clone --bare #{bundle_path} #{repo_path})
        _output, status = Gitlab::Popen.popen(cmd)
        status.zero?
      end

      def tar_with_options(archive:, dir:, options:)
        execute(%W(tar -#{options} #{archive} -C #{dir} .))
      end

      def untar_with_options(archive:, dir:, options:)
        execute(%W(tar -#{options} #{archive} -C #{dir}))
      end

      def execute(cmd)
        _output, status = Gitlab::Popen.popen(cmd)
        status.zero?
      end
    end
  end
end
