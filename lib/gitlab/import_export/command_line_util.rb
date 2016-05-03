module Gitlab
  module ImportExport
    module CommandLineUtil
      def tar_cf(archive:, dir:)
        tar_with_options(archive: archive, dir: dir, options: 'cf')
      end

      def untar_zxf(archive:, dir:)
        untar_with_options(archive: archive, dir: dir, options: 'zxf')
      end

      def untar_xf(archive:, dir:)
        untar_with_options(archive: archive, dir: dir, options: 'xf')
      end

      def tar_czf(archive:, dir:)
        tar_with_options(archive: archive, dir: dir, options: 'czf')
      end

      def git_bundle(git_bin_path: Gitlab.config.git.bin_path, repo_path:, bundle_path:)
        cmd = %W(#{git_bin_path} --git-dir=#{repo_path} bundle create #{bundle_path} --all)
        _output, status = Gitlab::Popen.popen(cmd)
        status.zero?
      end

      def tar_with_options(archive:, dir:, options:)
        cmd = %W(tar -#{options} #{archive} -C #{dir} .)
        _output, status = Gitlab::Popen.popen(cmd)
        status.zero?
      end

      def untar_with_options(archive:, dir:, options:)
        cmd = %W(tar -#{options} #{archive} -C #{dir})
        _output, status = Gitlab::Popen.popen(cmd)
        status.zero?
      end
    end
  end
end
