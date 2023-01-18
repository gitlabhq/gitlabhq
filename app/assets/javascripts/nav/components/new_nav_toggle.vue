<script>
import { GlBadge, GlToggle } from '@gitlab/ui';
import axios from '~/lib/utils/axios_utils';
import { createAlert } from '~/flash';
import { s__ } from '~/locale';
import Tracking from '~/tracking';

export default {
  i18n: {
    badgeLabel: s__('NorthstarNavigation|Alpha'),
    sectionTitle: s__('NorthstarNavigation|Navigation redesign'),
    toggleMenuItemLabel: s__('NorthstarNavigation|New navigation'),
    toggleLabel: s__('NorthstarNavigation|Toggle new navigation'),
    updateError: s__(
      'NorthstarNavigation|Could not update the new navigation preference. Please try again later.',
    ),
  },
  components: {
    GlBadge,
    GlToggle,
  },
  props: {
    enabled: {
      type: Boolean,
      required: true,
    },
    endpoint: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      isEnabled: this.enabled,
    };
  },
  methods: {
    toggleNav() {
      this.isEnabled = !this.isEnabled;
      this.updateAndReload();
    },
    async updateAndReload() {
      try {
        await axios.put(this.endpoint, { user: { use_new_navigation: this.isEnabled } });

        Tracking.event(undefined, 'click_toggle', {
          label: this.enabled ? 'disable_new_nav_beta' : 'enable_new_nav_beta',
          property: 'navigation',
        });

        window.location.reload();
      } catch (error) {
        createAlert({
          message: this.$options.i18n.updateError,
          error,
        });
      }
    },
  },
};
</script>

<template>
  <li>
    <div
      class="gl-px-4 gl-py-2 gl-display-flex gl-justify-content-space-between gl-align-items-center"
    >
      <b>{{ $options.i18n.sectionTitle }}</b>
      <gl-badge variant="info">{{ $options.i18n.badgeLabel }}</gl-badge>
    </div>

    <div
      class="menu-item gl-cursor-pointer gl-display-flex! gl-justify-content-space-between gl-align-items-center"
      @click.prevent.stop="toggleNav"
    >
      {{ $options.i18n.toggleMenuItemLabel }}
      <gl-toggle :value="isEnabled" :label="$options.i18n.toggleLabel" label-position="hidden" />
    </div>
  </li>
</template>
