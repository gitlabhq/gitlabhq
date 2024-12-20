<script>
import { GlIcon, GlSprintf } from '@gitlab/ui';
import { localeDateFormat, isValidDate, newDate } from '~/lib/utils/datetime_utility';

export default {
  components: {
    GlIcon,
    GlSprintf,
  },
  props: {
    nextRunAt: {
      type: String,
      required: true,
    },
  },
  computed: {
    nextCleanupAt() {
      const date = newDate(this.nextRunAt);
      if (isValidDate(date)) {
        return localeDateFormat.asDateTimeFull.format(date);
      }
      return '';
    },
  },
};
</script>

<template>
  <div class="gl-flex gl-flex-col gl-gap-4 sm:gl-flex-row">
    <span class="gl-flex gl-items-center gl-gap-2" data-testid="enabled">
      <gl-icon name="check-circle-filled" variant="success" />{{ s__('ContainerRegistry|Enabled') }}
    </span>
    <span v-if="nextCleanupAt" data-testid="next-cleanup-at">
      <gl-sprintf
        :message="s__('ContainerRegistry|%{strongStart}Next cleanup on%{strongEnd} %{cleanupTime}')"
      >
        <template #strong="{ content }">
          <strong>{{ content }}</strong>
        </template>
        <template #cleanupTime>{{ nextCleanupAt }}</template>
      </gl-sprintf>
    </span>
  </div>
</template>
