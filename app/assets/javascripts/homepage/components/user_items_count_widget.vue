<script>
import { GlIcon, GlLink, GlSkeletonLoader } from '@gitlab/ui';
import timeagoMixin from '~/vue_shared/mixins/timeago';
import { InternalEvents } from '~/tracking';

export default {
  name: 'UserItemsCountWidget',
  components: {
    GlIcon,
    GlLink,
    GlSkeletonLoader,
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
    cardText: {
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
    isLoading() {
      return !this.hasError && this.userItems === null;
    },
    lastUpdatedAt() {
      return this.userItems?.nodes?.[0]?.updatedAt ?? null;
    },
    formattedCount() {
      return this.userItems?.count != null ? this.formatCount(this.userItems.count) : '-';
    },
    fullAriaLabel() {
      return `${this.cardText} ${this.linkText}`;
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
    class="focus: gl-flex-1 gl-cursor-pointer gl-rounded-[1rem] gl-bg-strong gl-p-2 !gl-no-underline hover:gl-bg-alpha-dark-16 dark:hover:gl-bg-alpha-light-24"
    :href="path"
    :aria-label="fullAriaLabel"
    variant="meta"
    @click="$emit('click-link')"
  >
    <div v-if="hasError" class="gl-m-2">
      <div class="gl-flex gl-flex-col gl-items-start gl-gap-4 gl-p-2">
        <gl-icon name="error" class="gl-text-danger" :size="16" />
        <p class="gl-text-size-h5 gl-mb-0 gl-text-subtle">
          {{ errorText }}
        </p>
      </div>
    </div>
    <div v-else class="gl-flex gl-h-full gl-flex-col">
      <div class="gl-mx-4 gl-my-3 gl-flex gl-items-center gl-justify-between">
        <h2 class="gl-my-0 gl-text-md gl-font-normal gl-text-subtle">
          {{ cardText }}
        </h2>
        <gl-icon class="gl-text-subtle" :name="iconName" :size="16" />
      </div>
      <div class="gl-grow gl-rounded-[.75rem] gl-bg-default gl-p-4">
        <div class="gl-m-0 gl-flex gl-items-center gl-gap-4">
          <div class="gl-heading-1 gl-m-0" data-testid="count">
            {{ formattedCount }}
          </div>
        </div>
        <h2 class="gl-heading-5 gl-mb-0 gl-font-normal">
          {{ linkText }}
        </h2>
        <span v-if="isLoading" data-testid="last-updated-at">
          <gl-skeleton-loader :width="80" :lines="1" />
        </span>
        <span v-else data-testid="last-updated-at" class="gl-text-sm gl-text-subtle">
          {{ lastUpdatedAt ? timeFormatted(lastUpdatedAt) : __('Just now') }}
        </span>
      </div>
    </div>
  </gl-link>
</template>
