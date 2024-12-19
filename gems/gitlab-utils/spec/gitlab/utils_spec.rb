# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Utils, feature_category: :shared do
  using RSpec::Parameterized::TableSyntax
  include StubENV

  delegate :to_boolean, :boolean_to_yes_no, :slugify, :which,
    :ensure_array_from_string, :bytes_to_megabytes,
    :append_path, :remove_leading_slashes, :allowlisted?,
    :decode_path, :ms_to_round_sec, to: :described_class

  describe '.allowlisted?' do
    let(:allowed_paths) { ['/home/foo', '/foo/bar', '/etc/passwd'] }

    it 'returns true if path is allowed' do
      expect(allowlisted?('/foo/bar', allowed_paths)).to be(true)
    end

    it 'returns false if path is not allowed' do
      expect(allowlisted?('/test/test', allowed_paths)).to be(false)
    end

    it 'returns false if path is in different case' do
      expect(allowlisted?('/Foo/bar', allowed_paths)).to be(false)
    end
  end

  describe '.decode_path' do
    it 'returns path unencoded for singled-encoded paths' do
      expect(decode_path('%2Fhome%2Fbar%3Fasd%3Dqwe')).to eq('/home/bar?asd=qwe')
    end

    it 'returns path when it is unencoded' do
      expect(decode_path('/home/bar?asd=qwe')).to eq('/home/bar?asd=qwe')
    end

    [
      '..%252F..%252F..%252Fetc%252Fpasswd',
      '%25252Fresult%25252Fchosennickname%25253D%252522jj%252522'
    ].each do |multiple_encoded_path|
      it 'raises an exception when the path is multiple-encoded' do
        expect { decode_path(multiple_encoded_path) }.to raise_error(/path #{multiple_encoded_path} is not allowed/)
      end
    end
  end

  describe '.slugify' do
    where(:original, :allow_dots, :expected) do
      'TEST'                     | false | 'test'
      'project_with_underscores' | false | 'project-with-underscores'
      'namespace/project'        | false | 'namespace-project'
      ('a' * 70)                 | false | ('a' * 63)
      'test_trailing_'           | false | 'test-trailing'
      '17.9'                     | false | '17-9'
      '..17.9..'                 | true  | '17.9'
      '-.-.17.9-.-.'             | true  | '17.9'
      '17..9'                    | true  | '17..9'
      '17.9'                     | nil   | '17-9'
    end

    with_them do
      it "slugifies path according to settings" do
        expect(slugify(original, allow_dots: allow_dots)).to eq(expected)
      end
    end
  end

  describe '.ms_to_round_sec' do
    where(:original, :expected) do
      1999.8999     | 1.9999
      12384         | 12.384
      333           | 0.333
      1333.33333333 | 1.333333
    end

    with_them do
      it "returns rounded seconds" do
        expect(ms_to_round_sec(original)).to eq(expected)
      end
    end
  end

  describe '.nlbr' do
    it 'replaces new lines with <br>' do
      expect(described_class.nlbr("<b>hello</b>\n<i>world</i>")).to eq("hello<br>world")
    end
  end

  describe '.remove_line_breaks' do
    where(:original, :expected) do
      "foo\nbar\nbaz"     | "foobarbaz"
      "foo\r\nbar\r\nbaz" | "foobarbaz"
      "foobar"            | "foobar"
    end

    with_them do
      it "replace line breaks with an empty string" do
        expect(described_class.remove_line_breaks(original)).to eq(expected)
      end
    end
  end

  describe '.to_boolean' do
    it 'accepts booleans' do
      expect(to_boolean(true)).to be(true)
      expect(to_boolean(false)).to be(false)
    end

    it 'converts a valid value to a boolean' do
      expect(to_boolean(true)).to be(true)
      expect(to_boolean('true')).to be(true)
      expect(to_boolean('YeS')).to be(true)
      expect(to_boolean('t')).to be(true)
      expect(to_boolean('1')).to be(true)
      expect(to_boolean(1)).to be(true)
      expect(to_boolean('ON')).to be(true)

      expect(to_boolean('FaLse')).to be(false)
      expect(to_boolean('F')).to be(false)
      expect(to_boolean('NO')).to be(false)
      expect(to_boolean('n')).to be(false)
      expect(to_boolean('0')).to be(false)
      expect(to_boolean(0)).to be(false)
      expect(to_boolean('oFF')).to be(false)
    end

    it 'converts an invalid value to nil' do
      expect(to_boolean('fals')).to be_nil
      expect(to_boolean('yeah')).to be_nil
      expect(to_boolean('')).to be_nil
      expect(to_boolean(nil)).to be_nil
    end

    it 'accepts a default value, and does not return it when a valid value is given' do
      expect(to_boolean(true, default: false)).to be(true)
      expect(to_boolean('true', default: false)).to be(true)
      expect(to_boolean('YeS', default: false)).to be(true)
      expect(to_boolean('t', default: false)).to be(true)
      expect(to_boolean('1', default: 'any value')).to be(true)
      expect(to_boolean('ON', default: 42)).to be(true)

      expect(to_boolean('FaLse', default: true)).to be(false)
      expect(to_boolean('F', default: true)).to be(false)
      expect(to_boolean('NO', default: true)).to be(false)
      expect(to_boolean('n', default: true)).to be(false)
      expect(to_boolean('0', default: 'any value')).to be(false)
      expect(to_boolean('oFF', default: 42)).to be(false)
    end

    it 'accepts a default value, and returns it when an invalid value is given' do
      expect(to_boolean('fals', default: true)).to eq(true)
      expect(to_boolean('yeah', default: false)).to eq(false)
      expect(to_boolean('', default: 'any value')).to eq('any value')
      expect(to_boolean(nil, default: 42)).to eq(42)
    end
  end

  describe '.boolean_to_yes_no' do
    it 'converts booleans to Yes or No' do
      expect(boolean_to_yes_no(true)).to eq('Yes')
      expect(boolean_to_yes_no(false)).to eq('No')
    end
  end

  describe '.which' do
    before do
      stub_env('PATH', '/sbin:/usr/bin:/home/joe/bin')
    end

    it 'finds the full path to an executable binary in order of appearance' do
      expect(File).to receive(:executable?).with('/sbin/tool').ordered.and_return(false)
      expect(File).to receive(:executable?).with('/usr/bin/tool').ordered.and_return(true)
      expect(File).not_to receive(:executable?).with('/home/joe/bin/tool')

      expect(which('tool')).to eq('/usr/bin/tool')
    end
  end

  describe '.ensure_array_from_string' do
    it 'returns the same array if given one' do
      arr = ['a', 4, true, { test: 1 }]

      expect(ensure_array_from_string(arr)).to eq(arr)
    end

    it 'turns comma-separated strings into arrays' do
      str = 'seven, eight, 9, 10'

      expect(ensure_array_from_string(str)).to eq(%w[seven eight 9 10])
    end
  end

  describe '.bytes_to_megabytes' do
    it 'converts bytes to megabytes' do
      bytes = 1.megabyte

      expect(bytes_to_megabytes(bytes)).to eq(1)
    end
  end

  describe '.append_path' do
    where(:host, :path, :result) do
      'http://test/'  | '/foo/bar'  |  'http://test/foo/bar'
      'http://test/'  | '//foo/bar' |  'http://test/foo/bar'
      'http://test//' | '/foo/bar'  |  'http://test/foo/bar'
      'http://test'   | 'foo/bar'   |  'http://test/foo/bar'
      'http://test//' | ''          |  'http://test/'
      'http://test//' | nil         |  'http://test/'
      ''              | '/foo/bar'  |  '/foo/bar'
      nil             | '/foo/bar'  |  '/foo/bar'
    end

    with_them do
      it 'makes sure there is only one slash as path separator' do
        expect(append_path(host, path)).to eq(result)
      end
    end
  end

  describe '.remove_leading_slashes' do
    where(:str, :result) do
      '/foo/bar'  |  'foo/bar'
      '//foo/bar' |  'foo/bar'
      '/foo/bar/' |  'foo/bar/'
      'foo/bar'   |  'foo/bar'
      ''          |  ''
      nil         |  ''
    end

    with_them do
      it 'removes leading slashes' do
        expect(remove_leading_slashes(str)).to eq(result)
      end
    end
  end

  describe '.ensure_utf8_size' do
    context 'with string is has less bytes than expected' do
      it 'backfills string with null characters' do
        transformed = described_class.ensure_utf8_size('a' * 10, bytes: 32)

        expect(transformed.bytesize).to eq 32
        expect(transformed).to eq(('a' * 10) + ('0' * 22))
      end
    end

    context 'with string size is exactly the one that is expected' do
      it 'returns original value' do
        transformed = described_class.ensure_utf8_size('a' * 32, bytes: 32)

        expect(transformed).to eq 'a' * 32
        expect(transformed.bytesize).to eq 32
      end
    end

    context 'when string contains a few multi-byte UTF characters' do
      it 'backfills string with null characters' do
        transformed = described_class.ensure_utf8_size('❤' * 6, bytes: 32)

        expect(transformed).to eq '❤❤❤❤❤❤' + ('0' * 14) # rubocop:disable Style/StringConcatenation
        expect(transformed.bytesize).to eq 32
      end
    end

    context 'when string has multiple multi-byte UTF chars exceeding 32 bytes' do
      it 'truncates string to 32 characters and backfills it if needed' do
        transformed = described_class.ensure_utf8_size('❤' * 18, bytes: 32)

        expect(transformed).to eq(('❤' * 10) + ('0' * 2))
        expect(transformed.bytesize).to eq 32
      end
    end
  end

  describe '.deep_indifferent_access' do
    let(:hash) do
      { "variables" => [{ "key" => "VAR1", "value" => "VALUE2" }] }
    end

    subject { described_class.deep_indifferent_access(hash) }

    it 'allows to access hash keys with symbols' do
      expect(subject[:variables]).to be_a(Array)
    end

    it 'allows to access array keys with symbols' do
      expect(subject[:variables].first[:key]).to eq('VAR1')
    end
  end

  describe '.deep_symbolized_access' do
    let(:hash) do
      { "variables" => [{ "key" => "VAR1", "value" => "VALUE2" }] }
    end

    subject { described_class.deep_symbolized_access(hash) }

    it 'allows to access hash keys with symbols' do
      expect(subject[:variables]).to be_a(Array)
    end

    it 'allows to access array keys with symbols' do
      expect(subject[:variables].first[:key]).to eq('VAR1')
    end
  end

  describe '.try_megabytes_to_bytes' do
    context 'when the size can be converted to megabytes' do
      it 'returns the size in megabytes' do
        size = described_class.try_megabytes_to_bytes(1)

        expect(size).to eq(1.megabytes)
      end
    end

    context 'when the size can not be converted to megabytes' do
      it 'returns the input size' do
        size = described_class.try_megabytes_to_bytes('foo')

        expect(size).to eq('foo')
      end
    end
  end

  describe '.string_to_ip_object' do
    it 'returns nil when string is nil' do
      expect(described_class.string_to_ip_object(nil)).to eq(nil)
    end

    it 'returns nil when string is invalid IP' do
      expect(described_class.string_to_ip_object('invalid ip')).to eq(nil)
      expect(described_class.string_to_ip_object('')).to eq(nil)
    end

    it 'returns IP object when string is valid IP' do
      expect(described_class.string_to_ip_object('192.168.1.1')).to eq(IPAddr.new('192.168.1.1'))
      expect(described_class.string_to_ip_object('::ffff:a9fe:a864')).to eq(IPAddr.new('::ffff:a9fe:a864'))
      expect(described_class.string_to_ip_object('[::ffff:a9fe:a864]')).to eq(IPAddr.new('::ffff:a9fe:a864'))
      expect(described_class.string_to_ip_object('127.0.0.0/28')).to eq(IPAddr.new('127.0.0.0/28'))
      expect(described_class.string_to_ip_object('1:0:0:0:0:0:0:0/124')).to eq(IPAddr.new('1:0:0:0:0:0:0:0/124'))
    end
  end

  describe ".safe_downcase!" do
    where(:str, :result) do
      "test" | "test"
      "Test" | "test"
      "test" | "test"
      "Test" | "test"
    end

    with_them do
      it "downcases the string" do
        expect(described_class.safe_downcase!(str)).to eq(result)
      end
    end
  end

  describe '.parse_url' do
    it 'returns Addressable::URI object' do
      expect(described_class.parse_url('http://gitlab.com')).to be_instance_of(Addressable::URI)
    end

    it 'returns nil when URI cannot be parsed' do
      expect(described_class.parse_url('://gitlab.com')).to be nil
    end

    it 'returns nil with invalid parameter' do
      expect(described_class.parse_url(1)).to be nil
    end
  end

  describe '.add_url_parameters' do
    subject { described_class.add_url_parameters(url, params) }

    where(:url, :params, :expected_url) do
      nil                          | nil                | ''
      nil                          | { b: 3, a: 2 }     | '?a=2&b=3'
      'https://gitlab.com'         | nil                | 'https://gitlab.com'
      'https://gitlab.com'         | { b: 3, a: 2 }     | 'https://gitlab.com?a=2&b=3'
      'https://gitlab.com?a=1#foo' | { b: 3, 'a' => 2 } | 'https://gitlab.com?a=2&b=3#foo'
      'https://gitlab.com?a=1#foo' | [[:b, 3], [:a, 2]] | 'https://gitlab.com?a=2&b=3#foo'
    end

    with_them do
      it { is_expected.to eq(expected_url) }
    end
  end

  describe '.removes_sensitive_data_from_url' do
    it 'returns string object' do
      expect(described_class.removes_sensitive_data_from_url('http://gitlab.com')).to be_instance_of(String)
    end

    it 'returns nil when URI cannot be parsed' do
      expect(described_class.removes_sensitive_data_from_url('://gitlab.com')).to be nil
    end

    it 'returns nil with invalid parameter' do
      expect(described_class.removes_sensitive_data_from_url(1)).to be nil
    end

    it 'returns string with filtered access_token param' do
      expect(described_class.removes_sensitive_data_from_url('http://gitlab.com/auth.html#access_token=secret_token'))
        .to eq('http://gitlab.com/auth.html#access_token=filtered')
    end

    it 'returns string with filtered access_token param but other params preserved' do
      expect(described_class.removes_sensitive_data_from_url('http://gitlab.com/auth.html#access_token=secret_token&token_type=Bearer&state=test'))
        .to include('&token_type=Bearer', '&state=test')
    end
  end

  describe 'multiple_key_invert' do
    it 'invert keys with array values' do
      hash = {
        dast: [:vulnerabilities_count, :scanned_resources_count],
        sast: [:vulnerabilities_count]
      }
      expect(described_class.multiple_key_invert(hash)).to eq({
        vulnerabilities_count: [:dast, :sast],
        scanned_resources_count: [:dast]
      })
    end
  end

  describe '.stable_sort_by' do
    subject(:sorted_list) { described_class.stable_sort_by(list) { |obj| obj[:priority] } }

    context 'when items have the same priority' do
      let(:list) do
        [
          { name: 'obj 1', priority: 1 },
          { name: 'obj 2', priority: 1 },
          { name: 'obj 3', priority: 1 }
        ]
      end

      it 'does not change order in cases of ties' do
        expect(sorted_list).to eq(list)
      end
    end

    context 'when items have different priorities' do
      let(:list) do
        [
          { name: 'obj 1', priority: 2 },
          { name: 'obj 2', priority: 1 },
          { name: 'obj 3', priority: 3 }
        ]
      end

      it 'sorts items like the regular sort_by' do
        expect(sorted_list).to eq(
          [
            { name: 'obj 2', priority: 1 },
            { name: 'obj 1', priority: 2 },
            { name: 'obj 3', priority: 3 }
          ])
      end
    end
  end

  describe '.valid_brackets?' do
    where(:input, :allow_nested, :valid) do
      'no brackets'              | true  | true
      'no brackets'              | false | true
      'user[avatar]'             | true  | true
      'user[avatar]'             | false | true
      'user[avatar][friends]'    | true  | true
      'user[avatar][friends]'    | false | true
      'user[avatar[image[url]]]' | true  | true
      'user[avatar[image[url]]]' | false | false
      'user[avatar[]friends]'    | true  | true
      'user[avatar[]friends]'    | false | false
      'user[avatar]]'            | true  | false
      'user[avatar]]'            | false | false
      'user][avatar]]'           | true  | false
      'user][avatar]]'           | false | false
      'user[avatar'              | true  | false
      'user[avatar'              | false | false
    end

    with_them do
      it { expect(described_class.valid_brackets?(input, allow_nested: allow_nested)).to eq(valid) }
    end
  end

  describe '.restrict_within_concurrent_ruby' do
    it 'assigns restrict_within_concurrent_ruby to the current thread and ensures it restores' do
      expect(Thread.current[:restrict_within_concurrent_ruby]).to be_nil

      described_class.restrict_within_concurrent_ruby do
        expect(Thread.current[:restrict_within_concurrent_ruby]).to be(true)
      end

      expect(Thread.current[:restrict_within_concurrent_ruby]).to be_nil
    end
  end

  describe '.allow_within_concurrent_ruby' do
    it 'assigns restrict_within_concurrent_ruby false to the current thread and ensures it restores' do
      expect(Thread.current[:restrict_within_concurrent_ruby]).to be_nil

      described_class.allow_within_concurrent_ruby do
        expect(Thread.current[:restrict_within_concurrent_ruby]).to be(false)
      end

      expect(Thread.current[:restrict_within_concurrent_ruby]).to be_nil
    end

    it 'overrides the value of restrict_within_concurrent_ruby' do
      described_class.restrict_within_concurrent_ruby do
        described_class.allow_within_concurrent_ruby do
          expect(Thread.current[:restrict_within_concurrent_ruby]).to be(false)
        end
      end
    end
  end

  describe '.raise_if_concurrent_ruby!' do
    subject(:raise_if_concurrent_ruby!) { described_class.raise_if_concurrent_ruby!('test') }

    it 'raises an exception when running within a concurrent Ruby thread' do
      block = proc do
        expect { raise_if_concurrent_ruby! }.to raise_error(Gitlab::Utils::ConcurrentRubyThreadIsUsedError,
          "Cannot run 'test' if running from `Concurrent::Promise`.")
      end

      described_class.restrict_within_concurrent_ruby(&block)
    end

    it 'does not raise an exception when not running within a concurrent Ruby thread' do
      expect { raise_if_concurrent_ruby! }.not_to raise_error
    end
  end

  describe '.to_rails_log_level' do
    context 'with valid user input' do
      where(:input, :expected_level) do
        ::Logger::DEBUG   | :debug
        ::Logger::INFO    | :info
        ::Logger::WARN    | :warn
        ::Logger::ERROR   | :error
        ::Logger::FATAL   | :fatal
        ::Logger::UNKNOWN | :unknown
        0                 | :debug
        1                 | :info
        2                 | :warn
        3                 | :error
        4                 | :fatal
        5                 | :unknown
        '0'               | :debug
        '1'               | :info
        '2'               | :warn
        '3'               | :error
        '4'               | :fatal
        '5'               | :unknown
        'debug'           | :debug
        'info'            | :info
        'warn'            | :warn
        'error'           | :error
        'fatal'           | :fatal
        'unknown'         | :unknown
        'DEBUG'           | :debug
        'INFO'            | :info
        'WARN'            | :warn
        'ERROR'           | :error
        'FATAL'           | :fatal
        'UNKNOWN'         | :unknown
        :debug            | :debug
        :info             | :info
        :warn             | :warn
        :error            | :error
        :fatal            | :fatal
        :unknown          | :unknown
      end

      with_them do
        it 'returns the corresponding Rails log level' do
          expect(described_class.to_rails_log_level(input)).to eq(expected_level)
        end

        it 'ignores the fallback' do
          expect(described_class.to_rails_log_level(input, :debug)).to eq(expected_level)
        end
      end
    end

    context 'with invalid user input' do
      context 'without a fallback' do
        where(:input, :fallback, :expected_level) do
          6     | nil | :info
          'foo' | nil | :info
          ''    | nil | :info
          nil   | nil | :info
        end

        with_them do
          it 'returns :info' do
            expect(described_class.to_rails_log_level(input, fallback)).to eq(expected_level)
          end
        end
      end

      context 'with a valid fallback' do
        where(:input, :fallback, :expected_level) do
          6     | :debug          | :debug
          'foo' | :debug          | :debug
          ''    | :debug          | :debug
          nil   | :debug          | :debug
          6     | :info           | :info
          'foo' | :info           | :info
          ''    | :info           | :info
          nil   | :info           | :info
          6     | ::Logger::DEBUG | :debug
          'foo' | 'warn'          | :warn
          ''    | 'ERROR'         | :error
        end

        with_them do
          it 'returns the fallback' do
            expect(described_class.to_rails_log_level(input, fallback)).to eq(expected_level)
          end
        end
      end

      context 'with an invalid fallback' do
        where(:input, :fallback, :expected_level) do
          6     | 6     | :info
          'foo' | 'foo' | :info
          ''    | ''    | :info
          nil   | nil   | :info
        end

        with_them do
          it 'returns :info' do
            expect(described_class.to_rails_log_level(input, fallback)).to eq(expected_level)
          end
        end
      end
    end
  end

  describe '.deep_sort_hash' do
    it 'recursively sorts a hash' do
      hash = {
        z: "record-z",
        e: { y: "nested-record-y", a: "nested-record-a", b: "nested-record-b" },
        c: {
          m: {
            p: "doubly-nested-record-p",
            o: "doubly-nested-record-o"
          },
          k: {
            v: "doubly-nested-record-v",
            u: "doubly-nested-record-u"
          }
        }
      }
      expect(JSON.generate(described_class.deep_sort_hash(hash))).to eq(JSON.generate({
        c: {
          k: {
            u: "doubly-nested-record-u",
            v: "doubly-nested-record-v"
          },
          m: {
            o: "doubly-nested-record-o",
            p: "doubly-nested-record-p"
          }

        },
        e: { a: "nested-record-a", b: "nested-record-b",
             y: "nested-record-y" },
        z: "record-z"
      }))
    end
  end
end
