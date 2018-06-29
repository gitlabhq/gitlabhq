describe ::QA::EE::Runtime::Geo do
  describe '.max_db_replication_time' do
    subject { described_class.max_db_replication_time }

    context 'when the environment variable is set' do
      it 'returns the environment variable as a float' do
        expect(QA::Runtime::Env).to receive(:geo_max_db_replication_time).and_return('2345')

        expect(subject).to eq(2345.0)
      end
    end

    context 'when the environment variable is not set' do
      it 'returns the default' do
        expect(subject).to eq(120.0)
      end
    end
  end

  describe '.max_file_replication_time' do
    subject { described_class.max_file_replication_time }

    context 'when the environment variable is set' do
      it 'returns the environment variable as a float' do
        expect(QA::Runtime::Env).to receive(:geo_max_file_replication_time).and_return('4321')

        expect(subject).to eq(4321.0)
      end
    end

    context 'when the environment variable is not set' do
      it 'returns the default' do
        expect(subject).to eq(120.0)
      end
    end
  end
end
