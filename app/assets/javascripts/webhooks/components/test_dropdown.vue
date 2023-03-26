<script>
import { GlDisclosureDropdown } from '@gitlab/ui';
import { __ } from '~/locale';

export default {
  name: 'HookTestDropdown',
  components: {
    GlDisclosureDropdown,
  },
  props: {
    items: {
      type: Array,
      required: true,
    },
    size: {
      type: String,
      required: false,
      default: undefined,
    },
  },
  computed: {
    webhookTriggers() {
      return this.items.map(({ text, href }) => ({
        text,
        href,
        extraAttrs: {
          'data-method': 'post',
        },
      }));
    },
  },
  i18n: {
    test: __('Test'),
  },
};
</script>

<template>
  <gl-disclosure-dropdown :toggle-text="$options.i18n.test" :items="webhookTriggers" :size="size" />
</template>
