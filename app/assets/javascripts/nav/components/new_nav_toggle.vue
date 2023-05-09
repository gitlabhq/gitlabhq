<script>
import { GlToggle, GlDisclosureDropdownItem } from '@gitlab/ui';
import axios from '~/lib/utils/axios_utils';
import { createAlert } from '~/alert';
import { s__ } from '~/locale';
import Tracking from '~/tracking';

export default {
  i18n: {
    sectionTitle: s__('NorthstarNavigation|Navigation redesign'),
    toggleMenuItemLabel: s__('NorthstarNavigation|New navigation'),
    toggleLabel: s__('NorthstarNavigation|Toggle new navigation'),
    updateError: s__(
      'NorthstarNavigation|Could not update the new navigation preference. Please try again later.',
    ),
  },
  components: {
    GlToggle,
    GlDisclosureDropdownItem,
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
    newNavigation: {
      type: Boolean,
      required: false,
      default: false,
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
          property: this.enabled ? 'nav_user_menu' : 'navigation_top',
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
  <gl-disclosure-dropdown-item v-if="newNavigation" @action="toggleNav">
    <div class="gl-new-dropdown-item-content">
      <div
        class="gl-new-dropdown-item-text-wrapper gl-display-flex! gl-justify-content-space-between gl-align-items-center gl-py-2!"
      >
        {{ $options.i18n.toggleMenuItemLabel }}
        <gl-toggle :value="isEnabled" :label="$options.i18n.toggleLabel" label-position="hidden" />
      </div>
    </div>
  </gl-disclosure-dropdown-item>

  <li v-else>
    <div
      class="gl-px-4 gl-py-2 gl-display-flex gl-justify-content-space-between gl-align-items-center"
    >
      <b>{{ $options.i18n.sectionTitle }}</b>
    </div>

    <div
      class="menu-item gl-cursor-pointer gl-display-flex! gl-justify-content-space-between gl-align-items-center"
      @click.prevent.stop="toggleNav"
    >
      {{ $options.i18n.toggleMenuItemLabel }}
      <gl-toggle
        :value="isEnabled"
        :label="$options.i18n.toggleLabel"
        label-position="hidden"
        data-qa-selector="new_navigation_toggle"
      />
    </div>
  </li>
</template>
