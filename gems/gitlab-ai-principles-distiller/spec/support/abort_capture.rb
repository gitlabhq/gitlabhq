# frozen_string_literal: true

require 'stringio'

module AbortCaptureHelper
  # `abort` writes to stderr then raises SystemExit, and a compound `.and output(...).to_stderr` only captures for
  # the first matcher, so capture once and assert against the string.
  def capture_abort_stderr
    original = $stderr
    $stderr = StringIO.new
    begin
      yield
    rescue SystemExit
      nil
    end
    $stderr.string
  ensure
    $stderr = original
  end
end
