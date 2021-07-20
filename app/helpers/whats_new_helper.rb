# frozen_string_literal: true

module WhatsNewHelper
  def whats_new_most_recent_release_items_count
    ReleaseHighlight.most_recent_item_count
  end

  def whats_new_version_digest
    ReleaseHighlight.most_recent_version_digest
  end

  def display_whats_new?
    (Gitlab.dev_env_org_or_com? || user_signed_in?) &&
    !Gitlab::CurrentSettings.current_application_settings.whats_new_variant_disabled?
  end

  def whats_new_variants
    ApplicationSetting.whats_new_variants
  end

  def whats_new_variants_label(variant)
    case variant
    when 'all_tiers'
      _("Enable What's new: All tiers")
    when 'current_tier'
      _("Enable What's new: Current tier only")
    when 'disabled'
      _("Disable What's new")
    end
  end

  def whats_new_variants_description(variant)
    case variant
    when 'all_tiers'
      _("Include new features from all tiers.")
    when 'current_tier'
      _("Only include features new to your current subscription tier.")
    when 'disabled'
      _("%{italic_start}What's new%{italic_end} is inactive and cannot be viewed.").html_safe % { italic_start: '<i>'.html_safe, italic_end: '</i>'.html_safe }
    end
  end
end
