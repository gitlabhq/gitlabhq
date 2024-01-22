<script>
import { GlLink, GlIcon } from '@gitlab/ui';
import { sprintf } from '~/locale';
import { HELP_LINK_ARIA_LABEL } from '~/usage_quotas/storage/constants';

export default {
  name: 'StorageTypeHelpLink',
  components: {
    GlLink,
    GlIcon,
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
      return sprintf(HELP_LINK_ARIA_LABEL, {
        linkTitle: this.storageType,
      });
    },
  },
};
</script>

<template>
  <gl-link :href="helpLinks[storageType]" target="_blank" :aria-label="ariaLabel">
    <gl-icon name="question-o" :size="12" />
  </gl-link>
</template>
