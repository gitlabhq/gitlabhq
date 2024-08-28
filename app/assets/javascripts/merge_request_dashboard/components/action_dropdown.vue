<script>
import { GlDisclosureDropdown } from '@gitlab/ui';
import { InternalEvents } from '~/tracking';
import { __ } from '~/locale';

const trackingMixin = InternalEvents.mixin();

export default {
  components: {
    GlDisclosureDropdown,
  },
  mixins: [trackingMixin],
  inject: {
    switchDashboardPath: { default: '' },
    dashboardLinkText: { default: __('Switch to old dashboard') },
    experimentEnabled: { default: true },
  },
  computed: {
    dropdownItems() {
      return [
        { id: 0, href: this.switchDashboardPath, text: this.dashboardLinkText },
        {
          id: 1,
          href: 'https://gitlab.com/gitlab-org/gitlab/-/issues/460910',
          text: __('Provide feedback'),
          extraAttrs: {
            target: '__blank',
            rel: 'noopener',
          },
        },
      ];
    },
  },
  methods: {
    action({ id }) {
      if (id === 1) return;

      this.trackEvent('toggle_merge_request_redesign', {
        value: Number(this.experimentEnabled),
      });
    },
  },
};
</script>

<template>
  <gl-disclosure-dropdown
    icon="preferences"
    :toggle-text="__('Open action menu')"
    text-sr-only
    placement="bottom-end"
    :items="dropdownItems"
    @action="action"
  />
</template>
