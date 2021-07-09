<script>
import { GlTooltipDirective, GlIcon } from '@gitlab/ui';
import {
  ASYNC_DELETE_IMAGE_ERROR_MESSAGE,
  CLEANUP_STATUS_SCHEDULED,
  CLEANUP_STATUS_ONGOING,
  CLEANUP_STATUS_UNFINISHED,
  UNFINISHED_STATUS,
  UNSCHEDULED_STATUS,
  SCHEDULED_STATUS,
  ONGOING_STATUS,
} from '../../constants/index';

export default {
  name: 'CleanupStatus',
  components: {
    GlIcon,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    status: {
      type: String,
      required: true,
      validator(value) {
        return [UNFINISHED_STATUS, UNSCHEDULED_STATUS, SCHEDULED_STATUS, ONGOING_STATUS].includes(
          value,
        );
      },
    },
  },
  i18n: {
    CLEANUP_STATUS_SCHEDULED,
    CLEANUP_STATUS_ONGOING,
    CLEANUP_STATUS_UNFINISHED,
    ASYNC_DELETE_IMAGE_ERROR_MESSAGE,
  },
  computed: {
    showStatus() {
      return this.status !== UNSCHEDULED_STATUS;
    },
    failedDelete() {
      return this.status === UNFINISHED_STATUS;
    },
    statusText() {
      return this.$options.i18n[`CLEANUP_STATUS_${this.status}`];
    },
    expireIconClass() {
      return this.failedDelete ? 'gl-text-orange-500' : '';
    },
  },
};
</script>

<template>
  <div v-if="showStatus" class="gl-display-inline-flex gl-align-items-center">
    <gl-icon name="expire" data-testid="main-icon" :class="expireIconClass" />
    <span class="gl-mx-2">
      {{ statusText }}
    </span>
    <gl-icon
      v-if="failedDelete"
      v-gl-tooltip="{ title: $options.i18n.ASYNC_DELETE_IMAGE_ERROR_MESSAGE }"
      :size="14"
      class="gl-text-black-normal"
      data-testid="extra-info"
      name="information"
    />
  </div>
</template>
