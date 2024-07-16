<script>
import { GlDisclosureDropdown } from '@gitlab/ui';
import { __ } from '~/locale';
import { BASE_ACTIONS } from './constants';

export default {
  name: 'ListActions',
  i18n: {
    actions: __('Actions'),
  },
  components: {
    GlDisclosureDropdown,
  },
  props: {
    // Can extend `BASE_ACTIONS` and/or add new actions.
    // Expected format: https://gitlab-org.gitlab.io/gitlab-ui/?path=/docs/base-new-dropdowns-disclosure--docs#setting-disclosure-dropdown-items
    actions: {
      type: Object,
      required: true,
    },
    availableActions: {
      type: Array,
      required: true,
    },
  },
  computed: {
    items() {
      return this.availableActions.reduce((accumulator, action) => {
        return [
          ...accumulator,
          {
            ...BASE_ACTIONS[action],
            ...this.actions[action],
          },
        ];
      }, []);
    },
  },
};
</script>

<template>
  <gl-disclosure-dropdown
    :items="items"
    icon="ellipsis_v"
    no-caret
    :toggle-text="$options.i18n.actions"
    text-sr-only
    placement="bottom-end"
    category="tertiary"
  />
</template>
