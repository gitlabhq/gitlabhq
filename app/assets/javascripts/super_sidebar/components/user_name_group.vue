<script>
import { GlDisclosureDropdownGroup, GlDisclosureDropdownItem, GlTooltip } from '@gitlab/ui';
import SafeHtml from '~/vue_shared/directives/safe_html';

import { s__ } from '~/locale';

export default {
  i18n: {
    user: {
      busy: s__('UserProfile|(Busy)'),
    },
  },
  components: {
    GlDisclosureDropdownGroup,
    GlDisclosureDropdownItem,
    GlTooltip,
  },
  directives: {
    SafeHtml,
  },
  props: {
    user: {
      required: true,
      type: Object,
    },
  },
  computed: {
    menuItem() {
      const item = {
        text: this.user.name,
      };
      if (this.user.has_link_to_profile) {
        item.href = this.user.link_to_profile;
      }
      return item;
    },
  },
};
</script>

<template>
  <gl-disclosure-dropdown-group>
    <gl-disclosure-dropdown-item :item="menuItem">
      <template #list-item>
        <span class="gl-display-flex gl-flex-direction-column">
          <span>
            <span class="gl-font-weight-bold">
              {{ user.name }}
            </span>
            <span v-if="user.status.busy" class="gl-text-gray-500">{{
              $options.i18n.user.busy
            }}</span>
          </span>

          <span class="gl-text-gray-400">@{{ user.username }}</span>

          <span
            v-if="user.status.customized"
            ref="statusTooltipTarget"
            data-testid="user-menu-status"
            class="gl-display-flex gl-align-items-center gl-mt-2 gl-font-sm"
          >
            <gl-emoji :data-name="user.status.emoji" class="gl-mr-1" />
            <span v-safe-html="user.status.message" class="gl-text-truncate"></span>
            <gl-tooltip
              :target="() => $refs.statusTooltipTarget"
              boundary="viewport"
              placement="bottom"
            >
              <span v-safe-html="user.status.message"></span>
            </gl-tooltip>
          </span>
        </span>
      </template>
    </gl-disclosure-dropdown-item>
  </gl-disclosure-dropdown-group>
</template>
