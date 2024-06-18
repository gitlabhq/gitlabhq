<script>
import { GlSkeletonLoader, GlEmptyState } from '@gitlab/ui';
import EMPTY_DISCUSSION_URL from '@gitlab/svgs/dist/illustrations/empty-state/empty-activity-md.svg';
import DesignDisclosure from '~/vue_shared/components/design_management/design_disclosure.vue';
import DesignDescription from './design_description.vue';

export default {
  components: {
    DesignDescription,
    DesignDisclosure,
    GlSkeletonLoader,
    GlEmptyState,
  },
  props: {
    design: {
      type: Object,
      required: true,
    },
    isLoading: {
      type: Boolean,
      required: true,
    },
    isOpen: {
      type: Boolean,
      required: true,
    },
  },
  computed: {
    showDescription() {
      return !this.isLoading && Boolean(this.design.descriptionHtml);
    },
  },
  EMPTY_DISCUSSION_URL,
};
</script>

<template>
  <design-disclosure :open="isOpen">
    <template #default>
      <div class="image-notes gl-h-full gl-pt-0">
        <design-description v-if="showDescription" :design="design" class="gl-my-5 gl-border-b" />
        <div v-if="isLoading" class="gl-my-5">
          <gl-skeleton-loader />
        </div>
        <template v-else>
          <gl-empty-state
            data-testid="new-discussion-disclaimer"
            :svg-path="$options.EMPTY_DISCUSSION_URL"
          />
          <slot name="reply-form"></slot>
        </template>
      </div>
    </template>
  </design-disclosure>
</template>
