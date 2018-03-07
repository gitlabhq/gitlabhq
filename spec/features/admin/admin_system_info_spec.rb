require 'spec_helper'

describe 'Admin System Info' do
  before do
    sign_in(create(:admin))
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
        expect(page).to have_content 'Memory Usage 4 GB / 16 GB'
        expect(page).to have_content 'Disk Usage'
        expect(page).to have_content 'Uptime'
      end
    end

    context 'when CPU info is not available' do
      before do
        allow(Vmstat).to receive(:cpu).and_raise(Errno::ENOENT)
        allow(Vmstat).to receive(:memory).and_return(memory)
        visit admin_system_info_path
      end

      it 'shows system info page with no CPU info' do
        expect(page).to have_content 'CPU Unable to collect CPU info'
        expect(page).to have_content 'Memory Usage 4 GB / 16 GB'
        expect(page).to have_content 'Disk Usage'
        expect(page).to have_content 'Uptime'
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
        expect(page).to have_content 'Memory Usage Unable to collect memory info'
        expect(page).to have_content 'Disk Usage'
        expect(page).to have_content 'Uptime'
      end
    end
  end
end
