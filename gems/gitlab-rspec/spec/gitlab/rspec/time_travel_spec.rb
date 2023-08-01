# frozen_string_literal: true

RSpec.describe 'time travel' do
  before(:all) do
    @original_time_zone = Time.zone
    Time.zone = 'Eastern Time (US & Canada)'
  end

  after(:all) do
    Time.zone = @original_time_zone
  end

  describe ':freeze_time' do
    it 'freezes time around a spec example', :freeze_time do
      expect { sleep 0.1 }.not_to change { Time.now.to_f }
    end
  end

  describe ':time_travel_to' do
    it 'time-travels to the specified date', time_travel_to: '2020-01-01' do
      expect(Date.current).to eq(Date.new(2020, 1, 1))
    end

    it 'time-travels to the specified date & time', time_travel_to: '2020-02-02 10:30:45 -0700' do
      expect(Time.current).to eq(Time.new(2020, 2, 2, 17, 30, 45, '+00:00'))
    end
  end
end
