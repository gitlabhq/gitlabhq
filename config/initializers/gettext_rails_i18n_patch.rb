# frozen_string_literal: true

class PoToJson
  # This is required to modify the JS locale file output to our import needs
  # Overwrites: https://github.com/webhippie/po_to_json/blob/master/lib/po_to_json.rb#L46
  def generate_for_jed(language, overwrite = {})
    @options = parse_options(overwrite.merge(language: language))
    @parsed ||= inject_meta(parse_document)

    generated = build_json_for(build_jed_for(@parsed))
    [
      "window.translations = #{generated};"
    ].join(" ")
  end
end
