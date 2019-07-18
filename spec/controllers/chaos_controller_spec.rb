# frozen_string_literal: true

require 'spec_helper'

describe ChaosController do
  describe '#leakmem' do
    it 'calls synchronously' do
      expect(Gitlab::Chaos).to receive(:leak_mem).with(100, 30.seconds)

      get :leakmem

      expect(response).to have_gitlab_http_status(200)
    end

    it 'call synchronously with params' do
      expect(Gitlab::Chaos).to receive(:leak_mem).with(1, 2.seconds)

      get :leakmem, params: { memory_mb: 1, duration_s: 2 }

      expect(response).to have_gitlab_http_status(200)
    end

    it 'calls asynchronously' do
      expect(Chaos::LeakMemWorker).to receive(:perform_async).with(100, 30.seconds)

      get :leakmem, params: { async: 1 }

      expect(response).to have_gitlab_http_status(200)
    end
  end

  describe '#cpu_spin' do
    it 'calls synchronously' do
      expect(Gitlab::Chaos).to receive(:cpu_spin).with(30.seconds)

      get :cpu_spin

      expect(response).to have_gitlab_http_status(200)
    end

    it 'calls synchronously with params' do
      expect(Gitlab::Chaos).to receive(:cpu_spin).with(3.seconds)

      get :cpu_spin, params: { duration_s: 3 }

      expect(response).to have_gitlab_http_status(200)
    end

    it 'calls asynchronously' do
      expect(Chaos::CpuSpinWorker).to receive(:perform_async).with(30.seconds)

      get :cpu_spin, params: { async: 1 }

      expect(response).to have_gitlab_http_status(200)
    end
  end

  describe '#db_spin' do
    it 'calls synchronously' do
      expect(Gitlab::Chaos).to receive(:db_spin).with(30.seconds, 1.second)

      get :db_spin

      expect(response).to have_gitlab_http_status(200)
    end

    it 'calls synchronously with params' do
      expect(Gitlab::Chaos).to receive(:db_spin).with(4.seconds, 5.seconds)

      get :db_spin, params: { duration_s: 4, interval_s: 5 }

      expect(response).to have_gitlab_http_status(200)
    end

    it 'calls asynchronously' do
      expect(Chaos::DbSpinWorker).to receive(:perform_async).with(30.seconds, 1.second)

      get :db_spin, params: { async: 1 }

      expect(response).to have_gitlab_http_status(200)
    end
  end

  describe '#sleep' do
    it 'calls synchronously' do
      expect(Gitlab::Chaos).to receive(:sleep).with(30.seconds)

      get :sleep

      expect(response).to have_gitlab_http_status(200)
    end

    it 'calls synchronously with params' do
      expect(Gitlab::Chaos).to receive(:sleep).with(5.seconds)

      get :sleep, params: { duration_s: 5 }

      expect(response).to have_gitlab_http_status(200)
    end

    it 'calls asynchronously' do
      expect(Chaos::SleepWorker).to receive(:perform_async).with(30.seconds)

      get :sleep, params: { async: 1 }

      expect(response).to have_gitlab_http_status(200)
    end
  end

  describe '#kill' do
    it 'calls synchronously' do
      expect(Gitlab::Chaos).to receive(:kill).with(no_args)

      get :kill

      expect(response).to have_gitlab_http_status(200)
    end

    it 'calls asynchronously' do
      expect(Chaos::KillWorker).to receive(:perform_async).with(no_args)

      get :kill, params: { async: 1 }

      expect(response).to have_gitlab_http_status(200)
    end
  end
end
