<script>
import { GlBadge, GlToggle } from '@gitlab/ui';
import axios from '~/lib/utils/axios_utils';
import { createAlert } from '~/flash';
import { s__ } from '~/locale';

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
    async toggleNav() {
      try {
        await axios.put(this.endpoint, { user: { use_new_navigation: !this.enabled } });
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
      <gl-badge>{{ $options.i18n.badgeLabel }}</gl-badge>
    </div>

    <div class="menu-item gl-display-flex! gl-justify-content-space-between gl-align-items-center">
      {{ $options.i18n.toggleMenuItemLabel }}
      <gl-toggle
        v-model="isEnabled"
        :label="$options.i18n.toggleLabel"
        label-position="hidden"
        @change="toggleNav"
      />
    </div>
  </li>
</template>
