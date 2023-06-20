# frozen_string_literal: true

# Similar to MASK_PASSWORD mechanism we do for EE, see:
# https://gitlab.com/gitlab-org/gitlab/-/blob/463bb1f855d71fadef931bd50f1692ee04f211a8/ee/app/models/ee/application_setting.rb#L15
# but for non-EE attributes.
module ApplicationSettingMaskedAttrs
  MASK = '*****'

  def ai_access_token=(value)
    return if value == MASK

    super
  end
end
