module Projects
  module ImportExport
    module CommandLineUtil
      def tar_cf(archive:, dir:)
        cmd = %W(tar -cf #{archive} -C #{dir} .)
        _output, status = Gitlab::Popen.popen(cmd)
        status.zero?
      end
    end
  end
end
