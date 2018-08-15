describe QA::Runtime::Wait do
  describe '#sleep' do
    it 'sleeps' do
      time_now = Time.now
      subject.sleep(timeout: 0.5)
      time_after_sleep = Time.now

      expect(time_after_sleep).to be > time_now
    end
  end

  describe '#until' do
    it 'waits until true' do
      expect(subject.until { true }).to be true
    end

    it 'raises TimeoutError if timeout is reached' do
      expect { subject.until(timeout: 0.5) { false } }
        .to raise_error(QA::Runtime::Wait::Timer::TimeoutError)
    end
  end
end
