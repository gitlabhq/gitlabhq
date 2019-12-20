# frozen_string_literal: true

class Admin::SystemInfoController < Admin::ApplicationController
  EXCLUDED_MOUNT_OPTIONS = %w[
    nobrowse
    read-only
    ro
  ].freeze

  EXCLUDED_MOUNT_TYPES = [
    'autofs',
    'binfmt_misc',
    'cgroup',
    'debugfs',
    'devfs',
    'devpts',
    'devtmpfs',
    'efivarfs',
    'fuse.gvfsd-fuse',
    'fuseblk',
    'fusectl',
    'hugetlbfs',
    'mqueue',
    'proc',
    'pstore',
    'rpc_pipefs',
    'securityfs',
    'sysfs',
    'tmpfs',
    'tracefs',
    'vfat'
  ].freeze

  def show
    @cpus = Vmstat.cpu rescue nil
    @memory = Vmstat.memory rescue nil
    mounts = Sys::Filesystem.mounts

    @disks = []
    mounts.each do |mount|
      mount_options = mount.options.split(',')

      next if (EXCLUDED_MOUNT_OPTIONS & mount_options).any?
      next if (EXCLUDED_MOUNT_TYPES & [mount.mount_type]).any?

      begin
        disk = Sys::Filesystem.stat(mount.mount_point)
        @disks.push({
          bytes_total: disk.bytes_total,
          bytes_used:  disk.bytes_used,
          disk_name:   mount.name,
          mount_path:  disk.path
        })
      rescue Sys::Filesystem::Error
      end
    end
  end
end
