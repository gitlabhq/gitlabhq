<script>
import { GlDisclosureDropdown, GlBadge } from '@gitlab/ui';
import { s__, __ } from '~/locale';

export default {
  name: 'CreatePersonalAccessTokenDropdown',
  components: {
    GlDisclosureDropdown,
    GlBadge,
  },
  inject: ['accessTokenGranularNewUrl', 'accessTokenLegacyNewUrl'],
  props: {},
  computed: {
    dropdownItems() {
      return [
        {
          text: this.$options.i18n.fineGrainedToken,
          href: this.accessTokenGranularNewUrl,
          description: this.$options.i18n.fineGrainedTokenDescription,
          badge: this.$options.i18n.beta,
        },
        {
          text: this.$options.i18n.legacyToken,
          href: this.accessTokenLegacyNewUrl,
          description: this.$options.i18n.legacyTokenDescription,
        },
      ];
    },
  },
  i18n: {
    buttonTitle: s__('AccessTokens|Generate token'),
    fineGrainedToken: s__('AccessTokens|Fine-grained token'),
    fineGrainedTokenDescription: s__(
      'AccessTokens|Limit scope to specific groups and projects and fine-grained permissions to resources.',
    ),
    legacyToken: s__('AccessTokens|Legacy token'),
    legacyTokenDescription: s__(
      'AccessTokens|Scoped to all groups and projects with broad permissions to resources.',
    ),
    beta: __('Beta'),
  },
};
</script>

<template>
  <gl-disclosure-dropdown
    :items="dropdownItems"
    :toggle-text="$options.i18n.buttonTitle"
    placement="bottom-end"
    fluid-width
  >
    <template #list-item="{ item }">
      <div class="gl-mx-3 gl-w-34">
        <div class="gl-font-bold">
          {{ item.text }}
          <gl-badge v-if="item.badge" class="gl-ml-2">
            {{ item.badge }}
          </gl-badge>
        </div>
        <div class="gl-mt-2 gl-text-subtle">{{ item.description }}</div>
      </div>
    </template>
  </gl-disclosure-dropdown>
</template>
