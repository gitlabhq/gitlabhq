<script>
import { GlDisclosureDropdown } from '@gitlab/ui';
import { s__ } from '~/locale';
import { InternalEvents } from '~/tracking';
import { CLICK_GENERATE_FINE_GRAINED_PERSONAL_ACCESS_TOKEN } from '../constants';

export default {
  name: 'CreatePersonalAccessTokenDropdown',
  components: {
    GlDisclosureDropdown,
  },
  mixins: [InternalEvents.mixin()],
  inject: {
    accessTokenGranularNewUrl: { default: '' },
    accessTokenLegacyNewUrl: { default: '' },
    granularTokensEnforced: { default: false },
  },
  props: {},
  computed: {
    dropdownItems() {
      const items = [
        {
          text: this.$options.i18n.fineGrainedToken,
          href: this.accessTokenGranularNewUrl,
          description: this.$options.i18n.fineGrainedTokenDescription,
        },
      ];

      if (!this.granularTokensEnforced) {
        items.push({
          text: this.$options.i18n.legacyToken,
          href: this.accessTokenLegacyNewUrl,
          description: this.$options.i18n.legacyTokenDescription,
          extraAttrs: { 'data-testid': 'create-legacy-token-item' },
        });
      }

      return items;
    },
  },
  methods: {
    handleDropdownAction(item) {
      if (item.href !== this.accessTokenGranularNewUrl) {
        return;
      }

      this.trackEvent(CLICK_GENERATE_FINE_GRAINED_PERSONAL_ACCESS_TOKEN);
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
  },
};
</script>

<template>
  <gl-disclosure-dropdown
    :items="dropdownItems"
    :toggle-text="$options.i18n.buttonTitle"
    size="small"
    placement="bottom-end"
    fluid-width
    data-testid="create-token-dropdown"
    @action="handleDropdownAction"
  >
    <template #list-item="{ item }">
      <div class="gl-mx-3 gl-w-34">
        <div class="gl-font-bold">
          {{ item.text }}
        </div>
        <div class="gl-mt-2 gl-text-subtle">{{ item.description }}</div>
      </div>
    </template>
  </gl-disclosure-dropdown>
</template>
