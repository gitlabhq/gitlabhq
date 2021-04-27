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
      _("What's new presents new features from all tiers to help you keep track of all new features.")
    when 'current_tier'
      _("What's new presents new features for your current subscription tier, while hiding new features not available to your subscription tier.")
    when 'disabled'
      _("What's new is disabled and can no longer be viewed.")
    end
  end
end
