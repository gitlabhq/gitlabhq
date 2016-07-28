module Gitlab
  module ImportExport
    module CommandLineUtil
      def tar_czf(archive:, dir:)
        tar_with_options(archive: archive, dir: dir, options: 'czf')
      end

      def untar_zxf(archive:, dir:)
        untar_with_options(archive: archive, dir: dir, options: 'zxf')
      end

      def git_bundle(repo_path:, bundle_path:)
        execute(%W(#{git_bin_path} --git-dir=#{repo_path} bundle create #{bundle_path} --all))
      end

      def git_unbundle(repo_path:, bundle_path:)
        execute(%W(#{git_bin_path} clone --bare #{bundle_path} #{repo_path}))
      end

      def git_restore_hooks
        execute(%W(#{Gitlab.config.gitlab_shell.path}/bin/create-hooks) + repository_storage_paths_args)
      end

      private

      def tar_with_options(archive:, dir:, options:)
        execute(%W(tar -#{options} #{archive} -C #{dir} .))
      end

      def untar_with_options(archive:, dir:, options:)
        execute(%W(tar -#{options} #{archive} -C #{dir}))
      end

      def execute(cmd)
        output, status = Gitlab::Popen.popen(cmd)
        @shared.error(Gitlab::ImportExport::Error.new(output.to_s)) unless status.zero?
        status.zero?
      end

      def git_bin_path
        Gitlab.config.git.bin_path
      end

      def copy_files(source, destination)
        # if we are copying files, create the destination folder
        destination_folder = File.file?(source) ? File.dirname(destination) : destination

        FileUtils.mkdir_p(destination_folder)
        FileUtils.copy_entry(source, destination)
        true
      end

      def repository_storage_paths_args
        Gitlab.config.repositories.storages.values
      end
    end
  end
end
