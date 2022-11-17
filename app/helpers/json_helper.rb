# frozen_string_literal: true

module JsonHelper
  # These two JSON helpers are short-form wrappers for the Gitlab::Json
  # class, which should be used in place of .to_json calls or calls to
  # the JSON class.
  def json_generate(*args)
    Gitlab::Json.generate(*args)
  end

  def json_parse(*args)
    Gitlab::Json.parse(*args)
  end
end
