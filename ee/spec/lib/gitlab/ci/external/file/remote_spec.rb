require 'spec_helper'

describe Gitlab::Ci::External::File::Remote do
  let(:remote_file) { described_class.new(location) }
  let(:location) { 'https://gitlab.com/gitlab-org/gitlab-ce/blob/1234/.gitlab-ci-1.yml' }
  let(:remote_file_content) do
    <<~HEREDOC
      before_script:
        - apt-get update -qq && apt-get install -y -qq sqlite3 libsqlite3-dev nodejs
        - ruby -v
        - which ruby
        - gem install bundler --no-ri --no-rdoc
        - bundle install --jobs $(nproc)  "${FLAGS[@]}"
    HEREDOC
  end

  describe "#valid?" do
    context 'when is a valid remote url' do
      before do
        WebMock.stub_request(:get, location).to_return(body: remote_file_content)
      end

      it 'should return true' do
        expect(remote_file.valid?).to be_truthy
      end
    end

    context 'with an irregular url' do
      let(:location) { 'not-valid://gitlab.com/gitlab-org/gitlab-ce/blob/1234/.gitlab-ci-1.yml' }

      it 'should return false' do
        expect(remote_file.valid?).to be_falsy
      end
    end

    context 'with a timeout' do
      before do
        allow(Gitlab::HTTP).to receive(:get).and_raise(Timeout::Error)
      end

      it 'should be falsy' do
        expect(remote_file.valid?).to be_falsy
      end
    end

    context 'when is not a yaml file' do
      let(:location) { 'https://asdasdasdaj48ggerexample.com' }

      it 'should be falsy' do
        expect(remote_file.valid?).to be_falsy
      end
    end
  end

  describe "#content" do
    context 'with a valid remote file' do
      before do
        WebMock.stub_request(:get, location).to_return(body: remote_file_content)
      end

      it 'should return the content of the file' do
        expect(remote_file.content).to eql(remote_file_content)
      end
    end

    context 'with a timeout' do
      before do
        allow(Gitlab::HTTP).to receive(:get).and_raise(Timeout::Error)
      end

      it 'should be falsy' do
        expect(remote_file.content).to be_falsy
      end
    end

    context 'with an invalid remote url' do
      let(:location) { 'https://asdasdasdaj48ggerexample.com' }

      before do
        WebMock.stub_request(:get, location).to_raise(SocketError.new('Some HTTP error'))
      end

      it 'should be nil' do
        expect(remote_file.content).to be_nil
      end
    end
  end

  describe "#error_message" do
    let(:location) { 'not-valid://gitlab.com/gitlab-org/gitlab-ce/blob/1234/.gitlab-ci-1.yml' }

    it 'should return an error message' do
      expect(remote_file.error_message).to eq("Remote file '#{location}' is not valid.")
    end
  end
end
