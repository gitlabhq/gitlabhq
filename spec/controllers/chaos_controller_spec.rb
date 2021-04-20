# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ChaosController do
  describe '#leakmem' do
    it 'calls synchronously' do
      expect(Gitlab::Chaos).to receive(:leak_mem).with(100, 30.seconds)

      get :leakmem

      expect(response).to have_gitlab_http_status(:ok)
    end

    it 'call synchronously with params' do
      expect(Gitlab::Chaos).to receive(:leak_mem).with(1, 2.seconds)

      get :leakmem, params: { memory_mb: 1, duration_s: 2 }

      expect(response).to have_gitlab_http_status(:ok)
    end

    it 'calls asynchronously' do
      expect(Chaos::LeakMemWorker).to receive(:perform_async).with(100, 30.seconds)

      get :leakmem, params: { async: 1 }

      expect(response).to have_gitlab_http_status(:ok)
    end
  end

  describe '#cpu_spin' do
    it 'calls synchronously' do
      expect(Gitlab::Chaos).to receive(:cpu_spin).with(30.seconds)

      get :cpu_spin

      expect(response).to have_gitlab_http_status(:ok)
    end

    it 'calls synchronously with params' do
      expect(Gitlab::Chaos).to receive(:cpu_spin).with(3.seconds)

      get :cpu_spin, params: { duration_s: 3 }

      expect(response).to have_gitlab_http_status(:ok)
    end

    it 'calls asynchronously' do
      expect(Chaos::CpuSpinWorker).to receive(:perform_async).with(30.seconds)

      get :cpu_spin, params: { async: 1 }

      expect(response).to have_gitlab_http_status(:ok)
    end
  end

  describe '#db_spin' do
    it 'calls synchronously' do
      expect(Gitlab::Chaos).to receive(:db_spin).with(30.seconds, 1.second)

      get :db_spin

      expect(response).to have_gitlab_http_status(:ok)
    end

    it 'calls synchronously with params' do
      expect(Gitlab::Chaos).to receive(:db_spin).with(4.seconds, 5.seconds)

      get :db_spin, params: { duration_s: 4, interval_s: 5 }

      expect(response).to have_gitlab_http_status(:ok)
    end

    it 'calls asynchronously' do
      expect(Chaos::DbSpinWorker).to receive(:perform_async).with(30.seconds, 1.second)

      get :db_spin, params: { async: 1 }

      expect(response).to have_gitlab_http_status(:ok)
    end
  end

  describe '#sleep' do
    it 'calls synchronously' do
      expect(Gitlab::Chaos).to receive(:sleep).with(30.seconds)

      get :sleep

      expect(response).to have_gitlab_http_status(:ok)
    end

    it 'calls synchronously with params' do
      expect(Gitlab::Chaos).to receive(:sleep).with(5.seconds)

      get :sleep, params: { duration_s: 5 }

      expect(response).to have_gitlab_http_status(:ok)
    end

    it 'calls asynchronously' do
      expect(Chaos::SleepWorker).to receive(:perform_async).with(30.seconds)

      get :sleep, params: { async: 1 }

      expect(response).to have_gitlab_http_status(:ok)
    end
  end

  describe '#kill' do
    it 'calls synchronously' do
      expect(Gitlab::Chaos).to receive(:kill).with('KILL')

      get :kill

      expect(response).to have_gitlab_http_status(:ok)
    end

    it 'calls asynchronously' do
      expect(Chaos::KillWorker).to receive(:perform_async).with('KILL')

      get :kill, params: { async: 1 }

      expect(response).to have_gitlab_http_status(:ok)
    end
  end

  describe '#quit' do
    it 'calls synchronously' do
      expect(Gitlab::Chaos).to receive(:kill).with('QUIT')

      get :quit

      expect(response).to have_gitlab_http_status(:ok)
    end

    it 'calls asynchronously' do
      expect(Chaos::KillWorker).to receive(:perform_async).with('QUIT')

      get :quit, params: { async: 1 }

      expect(response).to have_gitlab_http_status(:ok)
    end
  end

  describe '#gc' do
    let(:gc_stat) { GC.stat.stringify_keys }

    it 'runs a full GC on the current web worker' do
      expect(Prometheus::PidProvider).to receive(:worker_id).and_return('worker-0')
      expect(Gitlab::Chaos).to receive(:run_gc).and_return(gc_stat)

      post :gc

      expect(response).to have_gitlab_http_status(:ok)
      expect(response_json['worker_id']).to eq('worker-0')
      expect(response_json['gc_stat']).to eq(gc_stat)
    end
  end

  def response_json
    Gitlab::Json.parse(response.body)
  end
end
