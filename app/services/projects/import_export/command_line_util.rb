module Projects
  module ImportExport
    module CommandLineUtil
      def tar_cf(archive:, dir:)
        cmd = %W(tar -cf #{archive} -C #{dir} .)
        _output, status = Gitlab::Popen.popen(cmd)
        status.zero?
      end

      def git_bundle(git_bin_path: Gitlab.config.git.bin_path, repo_path:, bundle_path:)
        cmd = %W(#{git_bin_path} --git-dir=#{repo_path} bundle create #{bundle_path} --all)
        _output, status = Gitlab::Popen.popen(cmd)
        status.zero?
      end
    end
  end
end
