<script>
import { GlBadge, GlLink } from '@gitlab/ui';
import { STATUSES, STATUS_ICON_MAP } from '~/import_entities/constants';

export default {
  components: {
    GlBadge,
    GlLink,
  },

  props: {
    hasFailures: {
      type: Boolean,
      required: false,
      default: false,
    },
    failuresHref: {
      type: String,
      required: false,
      default: '',
    },
    status: {
      type: String,
      required: true,
    },
  },

  computed: {
    isPartial() {
      return this.status === STATUSES.FINISHED && this.hasFailures;
    },

    mappedStatus() {
      if (this.isPartial) {
        return STATUS_ICON_MAP[STATUSES.PARTIAL];
      }

      return STATUS_ICON_MAP[this.status];
    },
  },
};
</script>

<template>
  <div>
    <gl-badge :icon="mappedStatus.icon" :variant="mappedStatus.variant" icon-size="sm">
      {{ mappedStatus.text }}
    </gl-badge>

    <div v-if="failuresHref" class="gl-mt-2">
      <gl-link :href="failuresHref">{{ s__('Import|Show errors') }} &gt;</gl-link>
    </div>
  </div>
</template>
