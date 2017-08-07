require 'spec_helper'

describe SshHostKey do
  include ReactiveCachingHelpers

  keys = [
    SSHKeygen.generate,
    SSHKeygen.generate
  ]

  # Purposefully ordered so that `sort` will make changes
  known_hosts = <<~EOF
    example.com #{keys[0]} git@localhost
    @revoked other.example.com #{keys[1]} git@localhost
  EOF

  def stub_ssh_keyscan(args, status: true, stdout: "", stderr: "")
    stdin = StringIO.new
    stdout = double(:stdout, read: stdout)
    stderr = double(:stderr, read: stderr)
    wait_thr = double(:wait_thr, value: double(success?: status))

    expect(Open3).to receive(:popen3).with({}, 'ssh-keyscan', *args).and_yield(stdin, stdout, stderr, wait_thr)

    stdin
  end

  let(:project) { build(:project, :mirror) }

  subject(:ssh_host_key) { described_class.new(project: project, url: 'ssh://example.com:2222') }

  describe '#fingerprints', use_clean_rails_memory_store_caching: true do
    it 'returns an array of indexed fingerprints when the cache is filled' do
      stub_reactive_cache(ssh_host_key, known_hosts: known_hosts)

      expected = keys
        .map { |data| Gitlab::KeyFingerprint.new(data) }
        .each_with_index
        .map { |key, i| { bits: key.bits, fingerprint: key.fingerprint, type: key.type, index: i } } 

      expect(ssh_host_key.fingerprints.as_json).to eq(expected)
    end

    it 'returns an empty array when the cache is empty' do
      expect(ssh_host_key.fingerprints).to eq([])
    end
  end

  describe '#fingerprints', use_clean_rails_memory_store_caching: true do
    it 'returns an array of indexed fingerprints when the cache is filled' do
      key1 = SSHKeygen.generate
      key2 = SSHKeygen.generate

      known_hosts = "example.com #{key1} git@localhost\n\n\n@revoked other.example.com #{key2} git@localhost\n"
      stub_reactive_cache(ssh_host_key, known_hosts: known_hosts)

      expect(ssh_host_key.fingerprints.as_json).to eq(
        [
          { bits: 2048, fingerprint: Gitlab::KeyFingerprint.new(key1).fingerprint, type: 'RSA', index: 0 },
          { bits: 2048, fingerprint: Gitlab::KeyFingerprint.new(key2).fingerprint, type: 'RSA', index: 3 }
        ]
      )
    end

    it 'returns an empty array when the cache is empty' do
      expect(ssh_host_key.fingerprints).to eq([])
    end
  end

  describe '#changes_project_import_data?' do
    subject { ssh_host_key.changes_project_import_data? }

    reversed = known_hosts.lines.reverse.join
    extra = known_hosts + "foo\nbar\n"

    [
      { a: known_hosts, b: extra,       result: true  },
      { a: known_hosts, b: "foo\n",     result: true  },
      { a: known_hosts, b: '',          result: true  },
      { a: known_hosts, b: nil,         result: true  },
      { a: known_hosts, b: known_hosts, result: false },
      { a: reversed,    b: known_hosts, result: false },
      { a: extra,       b: "foo\n",     result: true  },
      { a: '',          b: '',          result: false },
      { a: nil,         b: nil,         result: false },
      { a: '',          b: nil,         result: false }
    ].each_with_index do |spec, index|
      it "is #{spec[:result]} for test case #{index}" do
        expect(ssh_host_key).to receive(:known_hosts).and_return(spec[:a])
        project.import_data.ssh_known_hosts = spec[:b]

        is_expected.to eq(spec[:result])
      end

      # Comparisons should be symmetrical, so test the reverse too
      it "is #{spec[:result]} for test case #{index} (reversed)" do
        expect(ssh_host_key).to receive(:known_hosts).and_return(spec[:b])
        project.import_data.ssh_known_hosts = spec[:a]

        is_expected.to eq(spec[:result])
      end
    end
  end

  describe '#calculate_reactive_cache' do
    subject(:cache) { ssh_host_key.calculate_reactive_cache }

    it 'writes the hostname to STDIN' do
      stdin = stub_ssh_keyscan(%w[-T 5 -p 2222 -f-])

      cache

      expect(stdin.string).to eq("example.com\n")
    end

    context 'successful key scan' do
      it 'stores the cleaned known_hosts data' do
        stub_ssh_keyscan(%w[-T 5 -p 2222 -f-], stdout: "KEY 1\nKEY 1\n\n# comment\nKEY 2\n")

        is_expected.to eq(known_hosts: "KEY 1\nKEY 2\n")
      end
    end

    context 'failed key scan (exit code 1)' do
      it 'returns a generic error' do
        stub_ssh_keyscan(%w[-T 5 -p 2222 -f-], stdout: 'blarg', status: false)

        is_expected.to eq(error: 'Failed to detect SSH host keys')
      end
    end

    context 'failed key scan (exit code 0)' do
      it 'returns a generic error' do
        stub_ssh_keyscan(%w[-T 5 -p 2222 -f-], stderr: 'Unknown host')

        is_expected.to eq(error: 'Failed to detect SSH host keys')
      end
    end
  end
end
