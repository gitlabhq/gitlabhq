# frozen_string_literal: true

RSpec.describe Gitlab::Cng::Helpers::Spinner, :aggregate_failures do
  subject(:spin) do
    described_class.spin(spinner_message, **args) { success ? "success" : raise("error") }
  end

  let(:spinner) do
    instance_double(TTY::Spinner, auto_spin: nil, stop: nil, success: nil, error: nil, tty?: tty, spinning?: tty)
  end

  let(:spinner_message) { "spinner message" }
  let(:tty) { true }
  let(:success) { true }
  let(:success_mark) { Rainbow.new.wrap(TTY::Spinner::TICK).color(:green) }

  before do
    allow(TTY::Spinner).to receive(:new) { spinner }
  end

  context "without errors" do
    let(:args) { { done_message: "custom done" } }

    it "starts spinner and returns result of yielded block" do
      result = spin

      expect(spinner).to have_received(:auto_spin)
      expect(spinner).to have_received(:success).with("custom done")
      expect(result).to eq("success")
    end

    context "without tty" do
      let(:tty) { false }

      it "prints plain success message with default done message" do
        expect { spin }.to output("[#{Rainbow.new.wrap(success_mark)}] #{spinner_message} ... custom done\n").to_stdout
        expect(spinner).not_to have_received(:auto_spin)
        expect(spinner).not_to have_received(:stop)
      end
    end
  end

  context "with errors" do
    let(:success) { false }
    let(:error_message) { "failed\nerror" }

    context "with raise_on_error: true" do
      let(:args) { { raise_on_error: true } }
      let(:error_mark) { Rainbow.new.wrap(TTY::Spinner::CROSS).color(:red) }

      it "raises error and prints red error message" do
        expect { spin }.to raise_error("error")
        expect(TTY::Spinner).to have_received(:new).with(
          "[:spinner] #{spinner_message} ...",
          format: :dots,
          success_mark: success_mark,
          error_mark: error_mark
        )
        expect(spinner).to have_received(:error).with(Rainbow.new.wrap(error_message).color(:red))
      end

      context "without tty" do
        let(:tty) { false }

        it "raises error and prints plain red error message" do
          output = "[#{error_mark}] #{spinner_message} ... #{Rainbow.new.wrap(error_message).color(:red)}\n"

          expect { expect { spin }.to raise_error("error") }.to output(output).to_stdout
          expect(spinner).not_to have_received(:auto_spin)
          expect(spinner).not_to have_received(:stop)
        end
      end
    end

    context "with exit_on_error: false" do
      let(:args) { { raise_on_error: false } }
      let(:error_mark) { Rainbow.new.wrap(TTY::Spinner::CROSS).color(:yellow) }

      it "does not raise error and prints warning in yellow" do
        spin

        expect(TTY::Spinner).to have_received(:new).with(
          "[:spinner] #{spinner_message} ...",
          format: :dots,
          success_mark: success_mark,
          error_mark: error_mark
        )
        expect(spinner).to have_received(:error).with(Rainbow.new.wrap(error_message).color(:yellow))
      end

      context "without tty" do
        let(:tty) { false }

        it "does not raise error and prints plain warning in yellow" do
          output = "[#{error_mark}] #{spinner_message} ... #{Rainbow.new.wrap(error_message).color(:yellow)}\n"

          expect { spin }.to output(output).to_stdout
          expect(spinner).not_to have_received(:auto_spin)
          expect(spinner).not_to have_received(:stop)
        end
      end
    end
  end
end
