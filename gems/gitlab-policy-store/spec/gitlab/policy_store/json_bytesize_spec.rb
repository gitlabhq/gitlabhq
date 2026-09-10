# frozen_string_literal: true

require "spec_helper"

RSpec.describe Gitlab::PolicyStore::JsonBytesize do
  let(:including_class) do
    Class.new do
      include Gitlab::PolicyStore::JsonBytesize

      def call(object)
        json_bytesize(object)
      end
    end
  end

  subject(:json_bytesize) { including_class.new.method(:call) }

  it "returns the same bytesize JSON.generate would produce" do
    object = { "name" => "eoq", "tiers" => %w[production] }

    expect(json_bytesize.call(object)).to eq(JSON.generate(object).bytesize)
  end

  it "returns nil for a string carrying an invalid byte sequence for its encoding" do
    malformed = (+"eoq\xFF").force_encoding("UTF-8")

    expect(json_bytesize.call({ "name" => malformed })).to be_nil
  end

  it "returns nil for an object nested more than 100 levels deep" do
    deeply_nested = {}
    cursor = deeply_nested
    101.times do |index|
      cursor[index.to_s] = {}
      cursor = cursor[index.to_s]
    end

    expect(json_bytesize.call(deeply_nested)).to be_nil
  end
end
