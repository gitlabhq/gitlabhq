# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Admin System information', feature_category: :shared do
  before do
    admin = create(:admin)
    sign_in(admin)
    enable_admin_mode!(admin)
  end

  describe 'GET /admin/system_info' do
    let(:cpu) { double(:cpu, length: 2) }
    let(:memory) { double(:memory, active_bytes: 4294967296, total_bytes: 17179869184) }

    context 'when all info is available' do
      before do
        allow(Vmstat).to receive(:cpu).and_return(cpu)
        allow(Vmstat).to receive(:memory).and_return(memory)
        visit admin_system_info_path
      end

      it 'shows system info page' do
        expect(page).to have_content 'CPU 2 cores'
        expect(page).to have_content 'Memory usage 4 GiB / 16 GiB'
        expect(page).to have_content 'Disk usage'
        expect(page).to have_content 'System started'
      end
    end

    context 'when CPU info is not available' do
      before do
        allow(Vmstat).to receive(:cpu).and_raise(Errno::ENOENT)
        allow(Vmstat).to receive(:memory).and_return(memory)
        visit admin_system_info_path
      end

      it 'shows system info page with no CPU info' do
        expect(page).to have_content 'Unable to collect CPU information'
        expect(page).to have_content 'Memory usage 4 GiB / 16 GiB'
        expect(page).to have_content 'Disk usage'
        expect(page).to have_content 'System started'
      end
    end

    context 'when memory info is not available' do
      before do
        allow(Vmstat).to receive(:cpu).and_return(cpu)
        allow(Vmstat).to receive(:memory).and_raise(Errno::ENOENT)
        visit admin_system_info_path
      end

      it 'shows system info page with no CPU info' do
        expect(page).to have_content 'CPU 2 cores'
        expect(page).to have_content 'Unable to collect memory information'
        expect(page).to have_content 'Disk usage'
        expect(page).to have_content 'System started'
      end
    end

    context 'when disk stat has zero bytes' do
      let(:disk_stat) do
        instance_double(Sys::Filesystem::Stat, bytes_total: 0, bytes_used: 0, path: '/run/snapd/ns/lxd.mnt')
      end

      let(:mounts) do
        [double(:mount, options: 'valid_option', mount_type: 'nsfs', name: 'nsfs', mount_point: double(:mount_point))]
      end

      before do
        allow(Vmstat).to receive(:cpu).and_return(cpu)
        allow(Vmstat).to receive(:memory).and_return(memory)
        allow(Sys::Filesystem).to receive(:mounts).and_return(mounts)
        allow(Sys::Filesystem).to receive(:stat).and_return(disk_stat)

        visit admin_system_info_path
      end

      it 'shows system info page with disk usage info' do
        expect(page.status_code).to eq 200

        expect(page).to have_content 'CPU 2 cores'
        expect(page).to have_content 'Memory usage 4 GiB / 16 GiB'
        expect(page).to have_content 'Disk usage 0 B / 0 B'
        expect(page).to have_content 'System started'
      end
    end
  end
end
