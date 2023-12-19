# frozen_string_literal: true
module Backup
  module Dump
    class Postgres
      include Backup::Helper

      # Owner can read/write, group no permission, others no permission
      FILE_PERMISSION = 0o600

      # Triggers PgDump and outputs to the provided file path
      #
      # @param [String] output_file_path full path to the output destination
      # @param [Gitlab::Backup::Cli::Utils::PgDump] pg_dump
      # @return [Boolean] whether pg_dump finished with success
      def dump(output_file_path, pg_dump)
        compress_rd, compress_wr = IO.pipe

        compress_pid = spawn(compress_cmd, in: compress_rd, out: [output_file_path, 'w', FILE_PERMISSION])
        compress_rd.close

        dump_pid = pg_dump.spawn(output: compress_wr)
        compress_wr.close

        [compress_pid, dump_pid].all? do |pid|
          Process.waitpid(pid)
          $?.success?
        end
      end
    end
  end
end
