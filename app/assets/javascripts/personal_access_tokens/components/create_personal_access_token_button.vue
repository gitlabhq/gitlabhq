<script>
import { GlDisclosureDropdown, GlDisclosureDropdownItem, GlBadge } from '@gitlab/ui';
import { s__, __ } from '~/locale';

export default {
  name: 'PersonalAccessTokenCreateDropdown',
  components: {
    GlDisclosureDropdown,
    GlDisclosureDropdownItem,
    GlBadge,
  },
  props: {},
  computed: {},
  i18n: {
    buttonTitle: s__('AccessTokens|Generate token'),
    fineGrainedToken: s__('AccessTokens|Fine-grained token'),
    fineGrainedTokenDescription: s__(
      'AccessTokens|Limit scope to specific groups and projects and fine-grained permissions to resources.',
    ),
    legacyToken: s__('AccessTokens|Broad-access token'),
    legacyTokenDescription: s__(
      'AccessTokens|Scoped to all groups and projects with broad permissions to resources.',
    ),
    beta: __('Beta'),
  },
};
</script>

<template>
  <gl-disclosure-dropdown
    :toggle-text="$options.i18n.buttonTitle"
    placement="bottom-end"
    fluid-width
  >
    <gl-disclosure-dropdown-item>
      <div class="gl-w-34 gl-p-4">
        <div class="gl-font-bold">
          {{ $options.i18n.fineGrainedToken }}
          <gl-badge class="gl-ml-2" variant="info">
            {{ $options.i18n.beta }}
          </gl-badge>
        </div>
        <div class="gl-mt-2 gl-text-subtle">
          {{ $options.i18n.fineGrainedTokenDescription }}
        </div>
      </div>
    </gl-disclosure-dropdown-item>

    <gl-disclosure-dropdown-item>
      <div class="gl-w-34 gl-px-4 gl-pb-4">
        <div class="gl-font-bold">
          {{ $options.i18n.legacyToken }}
        </div>
        <div class="gl-mt-2 gl-text-subtle">
          {{ $options.i18n.legacyTokenDescription }}
        </div>
      </div>
    </gl-disclosure-dropdown-item>
  </gl-disclosure-dropdown>
</template>
