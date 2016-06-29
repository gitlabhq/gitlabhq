class Admin::SystemInfoController < Admin::ApplicationController
  def show
    excluded_mounts = [
      "nobrowse",
      "read-only",
      "ro"
    ]

    system_info = Vmstat.snapshot
    mounts = Sys::Filesystem.mounts

    @disks = []
    mounts.each do |mount|
      options = mount.options.split(', ')

      next unless excluded_mounts.each { |em| break if options.include?(em) }

      disk = Sys::Filesystem.stat(mount.mount_point)
      @disks.push({
          bytes_total: disk.bytes_total,
          bytes_used:  disk.bytes_used,
          disk_name:   mount.name,
          mount_path:  disk.path
      })
    end

    @cpus = system_info.cpus.length

    @mem_used = system_info.memory.active_bytes
    @mem_total = system_info.memory.total_bytes
  end
end
