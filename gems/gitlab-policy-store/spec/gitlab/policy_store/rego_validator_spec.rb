# frozen_string_literal: true

require "spec_helper"
require "timeout"

RSpec.describe Gitlab::PolicyStore::RegoValidator do
  let(:engine) { Gitlab::Glaz.govern_policy_engine }

  describe ".validate!" do
    it "returns true for a program the engine parses" do
      expect(described_class.validate!(:policy_rego, "package governance\n\nallow := true\n")).to be(true)
    end

    it "raises ValidationError naming the field, the message, and the location" do
      program = "package governance\n\nviolation contains {\"msg\": \"x\" if {\n"

      expect { described_class.validate!("rules[2]", program) }
        .to raise_error(Gitlab::PolicyStore::ValidationError, /\Arules\[2\] is invalid: .+ \(at 3:\d+\)\z/)
    end

    it "raises ValidationError for a program without a package declaration" do
      expect { described_class.validate!(:scope_rego, "applies := true\n") }
        .to raise_error(Gitlab::PolicyStore::ValidationError, /\Ascope_rego is invalid: .+package.+ \(at 1:1\)\z/)
    end

    context "with the engine's response stubbed" do
      def stub_errors(errors)
        allow(engine).to receive(:validate).and_return({ valid: false, errors: errors })
      end

      it "omits a blank location" do
        stub_errors([{ message: "unexpected token", location: "" }, { message: "missing value", location: "  " }])

        expect { described_class.validate!(:policy_rego, "x") }
          .to raise_error(Gitlab::PolicyStore::ValidationError,
            "policy_rego is invalid: unexpected token; missing value")
      end

      it "truncates a message the engine padded with the offending source" do
        stub_errors([{ message: "m" * 1_500, location: "1:1" }])

        expect { described_class.validate!(:policy_rego, "x") }
          .to raise_error(Gitlab::PolicyStore::ValidationError) { |error|
            expect(error.message).to end_with("#{'m' * 1_000}... (at 1:1)")
          }
      end

      it "truncates by bytes without splitting a multibyte character" do
        stub_errors([{ message: "𝔘" * 300, location: "" }])

        expect { described_class.validate!(:policy_rego, "x") }
          .to raise_error(Gitlab::PolicyStore::ValidationError) { |error|
            expect(error.message).to end_with("#{'𝔘' * 250}...")
            expect(error.message).to be_valid_encoding
          }
      end
    end

    it "raises ValidationError for a program that is not valid UTF-8" do
      expect { described_class.validate!(:scope_rego, (+"package gitlab.scope\n\xFF").force_encoding("UTF-8")) }
        .to raise_error(Gitlab::PolicyStore::ValidationError, "scope_rego must be valid UTF-8")
    end

    it "raises ValidationError for a binary-tagged program that cannot be converted to UTF-8" do
      expect { described_class.validate!(:scope_rego, (+"package gitlab.scope\n\xFF").force_encoding("BINARY")) }
        .to raise_error(Gitlab::PolicyStore::ValidationError, "scope_rego must be valid UTF-8")
    end

    it "raises EngineError, a ValidationError, when the engine faults, keeping the fault as the cause" do
      allow(engine).to receive(:validate).and_raise(RuntimeError, "engine panicked")

      expect { described_class.validate!(:policy_rego, "x") }
        .to raise_error(Gitlab::PolicyStore::EngineError, "policy_rego could not be validated") { |error|
          expect(error).to be_a(Gitlab::PolicyStore::ValidationError)
          expect(error.cause).to have_attributes(class: RuntimeError, message: "engine panicked")
        }
    end

    it "raises EngineError when the engine rejects the request it built as malformed" do
      allow(engine).to receive(:validate).and_raise(ArgumentError, "bad protobuf")

      expect { described_class.validate!(:policy_rego, "x") }
        .to raise_error(Gitlab::PolicyStore::EngineError, "policy_rego could not be validated")
    end

    it "treats failure without a usable error list as an engine fault, not as a bare invalid" do
      allow(engine).to receive(:validate).and_return({ valid: false, errors: nil })

      expect { described_class.validate!(:policy_rego, "x") }
        .to raise_error(Gitlab::PolicyStore::EngineError, "policy_rego could not be validated")
    end

    it "treats failure with an empty error list as an engine fault" do
      allow(engine).to receive(:validate).and_return({ valid: false, errors: [] })

      expect { described_class.validate!(:policy_rego, "x") }
        .to raise_error(Gitlab::PolicyStore::EngineError, "policy_rego could not be validated")
    end

    it "refuses the save when the engine times out" do
      allow(engine).to receive(:validate).and_raise(Timeout::Error)

      expect { described_class.validate!(:policy_rego, "x") }
        .to raise_error(Gitlab::PolicyStore::EngineError, "policy_rego could not be validated")
    end
  end
end
