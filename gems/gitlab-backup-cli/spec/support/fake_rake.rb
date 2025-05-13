# frozen_string_literal: true

FakeRake = Struct.new(:fake_output, keyword_init: true) do
  def capture_each
    fake_output.each do |line|
      yield line[:stream], line[:output]
    end
  end
end
