# frozen_string_literal: true

describe QA::Support::Logger do

  it '' do
    expect { described_class.warn('test') }.to output(/WARN/).to_stdout_from_any_process
  end
end