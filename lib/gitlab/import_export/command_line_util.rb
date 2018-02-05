module Gitlab
  module ImportExport
    module CommandLineUtil
      DEFAULT_MODE = 0700

      def tar_czf(archive:, dir:)
        tar_with_options(archive: archive, dir: dir, options: 'czf')
      end

      def untar_zxf(archive:, dir:)
        untar_with_options(archive: archive, dir: dir, options: 'zxf')
      end

      def mkdir_p(path)
        FileUtils.mkdir_p(path, mode: DEFAULT_MODE)
        FileUtils.chmod(DEFAULT_MODE, path)
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
        @shared.error(Gitlab::ImportExport::Error.new(output.to_s)) unless status.zero? # rubocop:disable Gitlab/ModuleWithInstanceVariables
        status.zero?
      end

      def git_bin_path
        Gitlab.config.git.bin_path
      end

      def copy_files(source, destination)
        # if we are copying files, create the destination folder
        destination_folder = File.file?(source) ? File.dirname(destination) : destination

        mkdir_p(destination_folder)
        FileUtils.copy_entry(source, destination)
        true
      end
    end
  end
end
