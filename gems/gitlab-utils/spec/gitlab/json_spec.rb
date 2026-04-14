# frozen_string_literal: true

require "spec_helper"

# We can disable the cop that enforces the use of this class
# as we need to test around it.
#
RSpec.describe Gitlab::Json do
  subject(:json) { described_class }

  describe ".parse" do
    it "is aliased" do
      [:parse!, :load, :decode].each do |method|
        expect(described_class.method(method)).to eq(described_class.method(:parse))
      end
    end

    context "when legacy_mode is disabled by default" do
      it "parses an object" do
        expect(json.parse('{ "foo": "bar" }')).to eq({ "foo" => "bar" })
      end

      it "parses an array" do
        expect(json.parse('[{ "foo": "bar" }]')).to eq([{ "foo" => "bar" }])
      end

      it "parses a string" do
        expect(json.parse('"foo"', legacy_mode: false)).to eq("foo")
      end

      it "parses a true bool" do
        expect(json.parse("true", legacy_mode: false)).to be(true)
      end

      it "parses a false bool" do
        expect(json.parse("false", legacy_mode: false)).to be(false)
      end
    end

    context "when legacy_mode is enabled" do
      it "parses an object" do
        expect(json.parse('{ "foo": "bar" }', legacy_mode: true)).to eq({ "foo" => "bar" })
      end

      it "parses an array" do
        expect(json.parse('[{ "foo": "bar" }]', legacy_mode: true)).to eq([{ "foo" => "bar" }])
      end

      it "raises an error on a string" do
        expect { json.parse('"foo"', legacy_mode: true) }.to raise_error(JSON::ParserError)
      end

      it "raises an error on a true bool" do
        expect { json.parse("true", legacy_mode: true) }.to raise_error(JSON::ParserError)
      end

      it "raises an error on a false bool" do
        expect { json.parse("false", legacy_mode: true) }.to raise_error(JSON::ParserError)
      end
    end
  end

  describe ".parse!" do
    context "when legacy_mode is disabled by default" do
      it "parses an object" do
        expect(json.parse!('{ "foo": "bar" }')).to eq({ "foo" => "bar" })
      end

      it "parses an array" do
        expect(json.parse!('[{ "foo": "bar" }]')).to eq([{ "foo" => "bar" }])
      end

      it "parses a string" do
        expect(json.parse!('"foo"', legacy_mode: false)).to eq("foo")
      end

      it "parses a true bool" do
        expect(json.parse!("true", legacy_mode: false)).to be(true)
      end

      it "parses a false bool" do
        expect(json.parse!("false", legacy_mode: false)).to be(false)
      end
    end

    context "when legacy_mode is enabled" do
      it "parses an object" do
        expect(json.parse!('{ "foo": "bar" }', legacy_mode: true)).to eq({ "foo" => "bar" })
      end

      it "parses an array" do
        expect(json.parse!('[{ "foo": "bar" }]', legacy_mode: true)).to eq([{ "foo" => "bar" }])
      end

      it "raises an error on a string" do
        expect { json.parse!('"foo"', legacy_mode: true) }.to raise_error(JSON::ParserError)
      end

      it "raises an error on a true bool" do
        expect { json.parse!("true", legacy_mode: true) }.to raise_error(JSON::ParserError)
      end

      it "raises an error on a false bool" do
        expect { json.parse!("false", legacy_mode: true) }.to raise_error(JSON::ParserError)
      end
    end
  end

  describe ".dump" do
    it "dumps an object" do
      expect(json.dump({ "foo" => "bar" })).to eq('{"foo":"bar"}')
    end

    it "dumps an array" do
      expect(json.dump([{ "foo" => "bar" }])).to eq('[{"foo":"bar"}]')
    end

    it "dumps a string" do
      expect(json.dump("foo")).to eq('"foo"')
    end

    it "dumps a true bool" do
      expect(json.dump(true)).to eq("true")
    end

    it "dumps a false bool" do
      expect(json.dump(false)).to eq("false")
    end
  end

  describe ".generate" do
    let(:obj) do
      { test: true, "foo.bar" => "baz", is_json: 1, some: [1, 2, 3] }
    end

    it "is aliased" do
      expect(described_class.method(:encode)).to eq(described_class.method(:generate))
    end

    it "generates JSON" do
      expected_string = <<~STR.chomp
        {"test":true,"foo.bar":"baz","is_json":1,"some":[1,2,3]}
      STR

      expect(json.generate(obj)).to eq(expected_string)
    end

    it "allows you to customise the output" do
      opts = {
        indent: "  ",
        space: " ",
        space_before: " ",
        object_nl: "\n",
        array_nl: "\n"
      }

      result = json.generate(obj, opts)

      expected_string = <<~STR.chomp
        {
          "test" : true,
          "foo.bar" : "baz",
          "is_json" : 1,
          "some" : [
            1,
            2,
            3
          ]
        }
      STR

      expect(result).to eq(expected_string)
    end
  end

  describe ".pretty_generate" do
    let(:obj) do
      {
        test: true,
        "foo.bar" => "baz",
        is_json: 1,
        some: [1, 2, 3],
        more: { test: true },
        multi_line_empty_array: [],
        multi_line_empty_obj: {}
      }
    end

    it "generates pretty JSON" do
      expected_string = <<~STR.chomp
        {
          "test": true,
          "foo.bar": "baz",
          "is_json": 1,
          "some": [
            1,
            2,
            3
          ],
          "more": {
            "test": true
          },
          "multi_line_empty_array": [

          ],
          "multi_line_empty_obj": {
          }
        }
      STR

      expect(json.pretty_generate(obj)).to eq(expected_string)
    end

    it "allows you to customise the output" do
      opts = {
        space_before: " "
      }

      result = json.pretty_generate(obj, opts)

      expected_string = <<~STR.chomp
        {
          "test" : true,
          "foo.bar" : "baz",
          "is_json" : 1,
          "some" : [
            1,
            2,
            3
          ],
          "more" : {
            "test" : true
          },
          "multi_line_empty_array" : [

          ],
          "multi_line_empty_obj" : {
          }
        }
      STR

      expect(result).to eq(expected_string)
    end
  end

  describe Gitlab::Json::Precompiled do
    subject(:precompiled) { described_class.new(obj) }

    describe "#to_s" do
      subject(:result) { precompiled.to_s }

      context "when obj is a string" do
        let(:obj) { "{}" }

        it "returns a string" do
          expect(result).to eq("{}")
        end
      end

      context "when obj is an array" do
        let(:obj) { ["{\"foo\": \"bar\"}", "{}"] }

        it "returns a string" do
          expect(result).to eq("[{\"foo\": \"bar\"},{}]")
        end
      end

      context "when obj is an array of un-stringables" do
        let(:obj) { [BasicObject.new] }

        it "raises an error" do
          expect { result }.to raise_error(NoMethodError)
        end
      end

      context "when obj is something else" do
        let(:obj) { {} }

        it "raises an error" do
          expect { result }.to raise_error(described_class::UnsupportedFormatError)
        end
      end
    end
  end

  describe Gitlab::Json::LimitedEncoder do
    subject(:encoded) { described_class.encode(obj, limit: 10.kilobytes) }

    context 'when object size is acceptable' do
      let(:obj) { { test: true } }

      it 'returns json string' do
        expect(encoded).to eq("{\"test\":true}")
      end
    end

    context 'when object is too big' do
      let(:obj) { [{ test: true }] * 1000 }

      it 'raises LimitExceeded error' do
        expect { encoded }.to raise_error(
          Gitlab::Json::LimitedEncoder::LimitExceeded
        )
      end
    end

    context 'when object contains ASCII-8BIT encoding' do
      let(:obj) { [{ a: "\x8F" }] * 1000 }

      it 'does not raise encoding error' do
        expect { encoded }.not_to raise_error
        expect(encoded).to be_a(String)
        expect(encoded.size).to eq(10001)
      end
    end

    context 'when object contains a number that would serialize to too many digits' do
      context 'with a BigDecimal from scientific notation' do
        let(:obj) { { value: BigDecimal('9E9999999') } }

        it 'raises NumberLimitExceeded error' do
          expect { encoded }.to raise_error(
            Gitlab::Json::LimitedEncoder::NumberLimitExceeded
          )
        end
      end

      context 'with a very small BigDecimal' do
        let(:obj) { { value: BigDecimal('1E-9999999') } }

        it 'raises NumberLimitExceeded error' do
          expect { encoded }.to raise_error(
            Gitlab::Json::LimitedEncoder::NumberLimitExceeded
          )
        end
      end

      context 'with an integer exceeding the digit limit' do
        let(:obj) { { value: 10**1001 } }

        it 'raises NumberLimitExceeded error' do
          expect { encoded }.to raise_error(
            Gitlab::Json::LimitedEncoder::NumberLimitExceeded
          )
        end
      end

      context 'with a large negative integer exceeding the digit limit' do
        let(:obj) { { value: -(10**1001) } }

        it 'raises NumberLimitExceeded error' do
          expect { encoded }.to raise_error(
            Gitlab::Json::LimitedEncoder::NumberLimitExceeded
          )
        end
      end

      context 'with Infinity' do
        let(:obj) { { value: Float::INFINITY } }

        it 'raises NumberLimitExceeded error' do
          expect { encoded }.to raise_error(
            Gitlab::Json::LimitedEncoder::NumberLimitExceeded
          )
        end
      end

      context 'with a large number nested in a hash' do
        let(:obj) { { outer: { inner: BigDecimal('9E9999999') } } }

        it 'raises NumberLimitExceeded error' do
          expect { encoded }.to raise_error(
            Gitlab::Json::LimitedEncoder::NumberLimitExceeded
          )
        end
      end

      context 'with a large number nested in an array' do
        let(:obj) { [1, 2, BigDecimal('9E9999999')] }

        it 'raises NumberLimitExceeded error' do
          expect { encoded }.to raise_error(
            Gitlab::Json::LimitedEncoder::NumberLimitExceeded
          )
        end
      end
    end

    context 'when object contains numbers within the digit limit' do
      context 'with a large but safe integer' do
        let(:obj) { { value: 10_000_000_000 } }

        it 'returns json string' do
          expect(encoded).to eq('{"value":10000000000}')
        end
      end

      context 'with a safe negative integer' do
        let(:obj) { { value: -9_999_999_999 } }

        it 'returns json string' do
          expect(encoded).to eq('{"value":-9999999999}')
        end
      end

      context 'with a safe float' do
        let(:obj) { { value: 1.5e2 } }

        it 'returns json string' do
          expect(encoded).to eq('{"value":150.0}')
        end
      end

      context 'with a finite float near the max' do
        let(:obj) { { value: 1.0e308 } }

        it 'returns json string' do
          expect { encoded }.not_to raise_error
        end
      end

      context 'with zero' do
        let(:obj) { { value: 0 } }

        it 'returns json string' do
          expect(encoded).to eq('{"value":0}')
        end
      end

      context 'with safe numbers in nested structures' do
        let(:obj) { { a: [1, 2, 3], b: { c: 42 } } }

        it 'returns json string' do
          expect(encoded).to eq('{"a":[1,2,3],"b":{"c":42}}')
        end
      end

      context 'with string values' do
        let(:obj) { { text: "hello" } }

        it 'does not check string values' do
          expect(encoded).to eq('{"text":"hello"}')
        end
      end

      context 'with a BigDecimal within the limit' do
        let(:obj) { { value: BigDecimal('1.5E2') } }

        it 'returns json string' do
          expect { encoded }.not_to raise_error
        end
      end
    end
  end
end
