class Admin::SystemInfoController < Admin::ApplicationController
  def show
    system_info = Vmstat.snapshot
    @load = system_info.load_average.collect { |v| v.round(2) }.join(', ')

    @mem_used = Filesize.from("#{system_info.memory.active_bytes} B").to_s('GB')
    @mem_total = Filesize.from("#{system_info.memory.total_bytes} B").to_s('GB')

    @disk_used = Filesize.from("#{system_info.disks[0].used_bytes} B").to_s('GB')
    @disk_total = Filesize.from("#{system_info.disks[0].total_bytes} B").to_s('GB')
  end
end
