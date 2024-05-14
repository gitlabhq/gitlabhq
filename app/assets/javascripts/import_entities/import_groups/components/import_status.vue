<script>
import { GlBadge, GlLink } from '@gitlab/ui';
import { STATUSES, STATUS_ICON_MAP } from '~/import_entities/constants';

export default {
  components: {
    GlBadge,
    GlLink,
  },

  inject: {
    detailsPath: {
      default: undefined,
    },
  },

  props: {
    id: {
      type: Number,
      required: false,
      default: null,
    },
    entityId: {
      type: Number,
      required: false,
      default: null,
    },
    hasFailures: {
      type: Boolean,
      required: false,
      default: false,
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

    showDetails() {
      return Boolean(this.detailsPathWithId) && this.hasFailures;
    },

    detailsPathWithId() {
      if (!this.id || !this.entityId || !this.detailsPath) {
        return null;
      }

      return this.detailsPath
        .replace(':id', encodeURIComponent(this.id))
        .replace(':entity_id', encodeURIComponent(this.entityId));
    },
  },
};
</script>

<template>
  <div>
    <gl-badge :icon="mappedStatus.icon" :variant="mappedStatus.variant" size="md" icon-size="sm">
      {{ mappedStatus.text }}
    </gl-badge>

    <div v-if="showDetails" class="gl-mt-2">
      <gl-link :href="detailsPathWithId">{{ s__('Import|See failures') }}</gl-link>
    </div>
  </div>
</template>
