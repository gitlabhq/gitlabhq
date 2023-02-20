# frozen_string_literal: true

module JsonHelper
  # These two JSON helpers are short-form wrappers for the Gitlab::Json
  # class, which should be used in place of .to_json calls or calls to
  # the JSON class.
  def json_generate(...)
    Gitlab::Json.generate(...)
  end

  def json_parse(...)
    Gitlab::Json.parse(...)
  end
end
