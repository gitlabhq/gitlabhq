# frozen_string_literal: true

class Admin::SystemInfoController < Admin::ApplicationController
  feature_category :not_owned # rubocop:todo Gitlab/AvoidFeatureCategoryNotOwned

  EXCLUDED_MOUNT_OPTIONS = %w[
    nobrowse
    read-only
    ro
  ].freeze

  EXCLUDED_MOUNT_TYPES = [
    'autofs',
    'binfmt_misc',
    'bpf',
    'cgroup',
    'cgroup2',
    'configfs',
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
    @cpus = begin
      Vmstat.cpu
    rescue StandardError
      nil
    end
    @memory = begin
      Vmstat.memory
    rescue StandardError
      nil
    end
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
          bytes_used: disk.bytes_used,
          disk_name: mount.name,
          mount_path: disk.path
        })
      rescue Sys::Filesystem::Error
      end
    end
  end
end
