<script>
import { GlButton } from '@gitlab/ui';

const TRANSCEND_REGISTRATION_URL =
  'https://about.gitlab.com/events/transcend/virtual/?utm_medium=product&utm_campaign=eg_global_cmp_webcast_x_en_20260610_gitlabtranscend_virtual&utm_content=in-product-placement_x_x';

export default {
  name: 'TranscendPromoCard',
  components: {
    GlButton,
  },
  TRANSCEND_REGISTRATION_URL,
};
</script>

<template>
  <div class="whats-new-promo-card gl-border gl-mb-5 gl-rounded-lg gl-p-5">
    <h3 class="gl-heading-3-fixed gl-mb-3 gl-text-default">
      {{ s__('TranscendPromo|Register now for GitLab Transcend') }}
    </h3>

    <p class="gl-mb-3 gl-text-subtle">
      {{
        s__(
          'TranscendPromo|On June 10 (June 11 for AMER/APAC), join us online to see what’s new and what’s next. Learn through technical demos and a live Duo Agent Platform workshop focused on top use cases like code review automation, pipeline fixes, and more.',
        )
      }}
    </p>

    <gl-button
      :href="$options.TRANSCEND_REGISTRATION_URL"
      variant="confirm"
      target="_blank"
      data-testid="transcend-register-link"
      data-event-tracking="click_whats_new_transcend_register"
    >
      {{ __('Register now') }}
    </gl-button>
  </div>
</template>
