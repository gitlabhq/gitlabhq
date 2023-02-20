# frozen_string_literal: true
module Backup
  module Dump
    class Postgres
      include Backup::Helper

      FILE_PERMISSION = 0o600

      def dump(database_name, output_file, pgsql_args)
        compress_rd, compress_wr = IO.pipe
        compress_pid = spawn(gzip_cmd, in: compress_rd, out: [output_file, 'w', FILE_PERMISSION])
        compress_rd.close

        dump_pid = Process.spawn('pg_dump', *pgsql_args, database_name, out: compress_wr)
        compress_wr.close

        [compress_pid, dump_pid].all? do |pid|
          Process.waitpid(pid)
          $?.success?
        end
      end
    end
  end
end
