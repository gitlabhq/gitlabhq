<script>
import { GlLink } from '@gitlab/ui';
import HelpIcon from '~/vue_shared/components/help_icon/help_icon.vue';
import { sprintf, s__ } from '~/locale';

export default {
  name: 'StorageTypeHelpLink',
  components: {
    GlLink,
    HelpIcon,
  },
  props: {
    storageType: {
      type: String,
      required: true,
    },
    helpLinks: {
      type: Object,
      required: true,
    },
  },
  computed: {
    ariaLabel() {
      return sprintf(s__('UsageQuota|%{linkTitle} help link'), {
        linkTitle: this.storageType,
      });
    },
  },
};
</script>

<template>
  <gl-link :href="helpLinks[storageType]" target="_blank" :aria-label="ariaLabel" class="gl-ml-3">
    <help-icon />
  </gl-link>
</template>
