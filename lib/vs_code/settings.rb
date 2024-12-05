# frozen_string_literal: true

module VsCode
  module Settings
    DEFAULT_MACHINE = {
      id: 1,
      uuid: "3aa16b0f-652e-4850-8429-a00190dac6aa",
      version: 1,
      setting_type: "machines",
      machines: [
        {
          id: 1,
          name: "GitLab WebIDE",
          platform: "GitLab"
        }
      ]
    }.freeze
    EXTENSIONS = "extensions"
    SETTINGS_TYPES = %w[settings extensions globalState machines keybindings snippets tasks profiles].freeze
    DEFAULT_SESSION = "1"
    NO_CONTENT_ETAG = "0"
  end
end
