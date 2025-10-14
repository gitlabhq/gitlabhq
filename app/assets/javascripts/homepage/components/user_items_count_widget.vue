<script>
import { GlIcon, GlLink } from '@gitlab/ui';
import timeagoMixin from '~/vue_shared/mixins/timeago';
import { InternalEvents } from '~/tracking';

export default {
  name: 'UserItemsCountWidget',
  components: {
    GlIcon,
    GlLink,
  },
  mixins: [timeagoMixin, InternalEvents.mixin()],
  props: {
    hasError: {
      type: Boolean,
      required: true,
    },
    path: {
      type: String,
      required: true,
    },
    errorText: {
      type: String,
      required: true,
    },
    linkText: {
      type: String,
      required: true,
    },
    userItems: {
      type: Object,
      required: false,
      default: null,
    },
    iconName: {
      type: String,
      required: false,
      default: 'merge-request',
    },
  },
  computed: {
    lastUpdatedAt() {
      return this.userItems?.nodes?.[0]?.updatedAt ?? null;
    },
    formattedCount() {
      return this.userItems?.count != null ? this.formatCount(this.userItems.count) : '-';
    },
  },
  methods: {
    formatCount(count) {
      if (Math.abs(count) < 10000) {
        return new Intl.NumberFormat(navigator.language, {
          useGrouping: false,
        }).format(count);
      }
      return new Intl.NumberFormat(navigator.language, {
        notation: 'compact',
        compactDisplay: 'short',
        maximumFractionDigits: 1,
      }).format(count);
    },
  },
};
</script>

<template>
  <gl-link
    class="gl-border gl-flex-1 gl-cursor-pointer gl-rounded-lg gl-border-subtle gl-bg-subtle gl-px-4 gl-py-4 hover:gl-bg-gray-10 dark:hover:gl-bg-alpha-light-8"
    :href="path"
    :aria-label="linkText"
    variant="meta"
    @click="$emit('click-link')"
  >
    <div v-if="hasError" class="gl-m-2">
      <div class="gl-flex gl-flex-col gl-items-start gl-gap-4">
        <gl-icon name="error" class="gl-text-danger" :size="16" />
        <p class="gl-text-size-h5 gl-mb-0 gl-text-default">
          {{ errorText }}
        </p>
      </div>
    </div>
    <div v-else>
      <div class="gl-m-2 gl-flex gl-items-center gl-gap-4">
        <div class="gl-heading-1 gl-mb-0" data-testid="count">
          {{ formattedCount }}
        </div>
        <gl-icon :name="iconName" :size="16" />
      </div>
      <h2 class="gl-heading-5 gl-mb-0 gl-font-normal">
        {{ linkText }}
      </h2>
      <span v-if="lastUpdatedAt" data-testid="last-updated-at" class="gl-text-sm gl-text-subtle">
        {{ timeFormatted(lastUpdatedAt) }}
      </span>
    </div>
  </gl-link>
</template>
