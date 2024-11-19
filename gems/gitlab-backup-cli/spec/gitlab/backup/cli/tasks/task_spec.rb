# frozen_string_literal: true

RSpec.describe Gitlab::Backup::Cli::Tasks::Task do
  let(:context) { build_fake_context }
  let(:tmpdir) { Pathname.new(Dir.mktmpdir('task', temp_path)) }
  let(:metadata) { build(:backup_metadata) }

  subject(:task) { described_class.new(context: context) }

  after do
    FileUtils.rmtree(tmpdir)
  end

  context 'with unimplemented methods' do
    describe '.id' do
      it 'raises an error' do
        expect { described_class.id }.to raise_error(NotImplementedError)
      end
    end

    describe '#id' do
      it 'raises an error' do
        expect { task.id }.to raise_error(NotImplementedError)
      end
    end

    describe '#human_name' do
      it 'raises an error' do
        expect { task.human_name }.to raise_error(NotImplementedError)
      end
    end

    describe '#destination_path' do
      it 'raises an error' do
        expect { task.destination_path }.to raise_error(NotImplementedError)
      end
    end

    describe '#local' do
      it 'raises an error' do
        expect { task.send(:local) }.to raise_error(NotImplementedError)
      end
    end
  end

  describe '#backup!' do
    it 'delegates to target' do
      expect(task).to receive(:destination_path).and_return(tmpdir.join('test_task'))
      expect(task).to receive_message_chain(:target, :dump)

      task.backup!(tmpdir)
    end
  end

  describe '#restore!' do
    it 'delegates to target' do
      archive_directory = context.backup_basedir.join("this-is-a-fake-archive")
      expect(task).to receive(:destination_path).and_return(tmpdir.join('test_task'))
      expect(task).to receive_message_chain(:target, :restore)

      task.restore!(archive_directory)
    end
  end
end
