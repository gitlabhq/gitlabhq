<script>
import { GlButton, GlIcon, GlSkeletonLoader, GlTooltipDirective } from '@gitlab/ui';
import { TYPE_DESIGN } from '~/import/constants';
import { s__ } from '~/locale';
import ImportedBadge from '~/vue_shared/components/imported_badge.vue';
import CloseButton from './close_button.vue';
import DesignNavigation from './design_navigation.vue';

export default {
  i18n: {
    downloadButtonLabel: s__('DesignManagement|Download design'),
    hideCommentsButtonLabel: s__('DesignManagement|Hide comments'),
    showCommentsButtonLabel: s__('DesignManagement|Show comments'),
  },
  components: {
    GlButton,
    GlIcon,
    GlSkeletonLoader,
    ImportedBadge,
    CloseButton,
    DesignNavigation,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    workItemTitle: {
      type: String,
      required: true,
    },
    design: {
      type: Object,
      required: true,
    },
    designFilename: {
      type: String,
      required: true,
    },
    isLoading: {
      type: Boolean,
      required: true,
    },
    isSidebarOpen: {
      type: Boolean,
      required: true,
    },
    allDesigns: {
      type: Array,
      required: false,
      default: () => [],
    },
  },
  computed: {
    toggleCommentsButtonLabel() {
      return this.isSidebarOpen
        ? this.$options.i18n.hideCommentsButtonLabel
        : this.$options.i18n.showCommentsButtonLabel;
    },
  },
  TYPE_DESIGN,
};
</script>

<template>
  <header
    class="gl-flex gl-flex-col md:gl-flex-row md:gl-items-center gl-justify-between gl-max-w-full gl-bg-white gl-py-4 gl-pl-5 gl-border-b js-design-header"
  >
    <div class="gl-flex gl-flex-row gl-items-center gl-mb-3 md:gl-mb-0 gl-overflow-hidden">
      <div class="gl-overflow-hidden gl-flex gl-mr-3">
        <gl-skeleton-loader v-if="isLoading" :lines="1" />
        <h2 v-else class="gl-flex gl-items-center gl-overflow-hidden gl-m-0 gl-text-base">
          <span class="gl-text-truncate gl-text-gray-900 gl-no-underline">
            {{ workItemTitle }}
          </span>
          <gl-icon name="chevron-right" class="gl-text-gray-200 gl-flex-shrink-0" />
          <span class="gl-text-truncate gl-font-normal">{{ design.filename }}</span>
          <imported-badge
            v-if="design.imported"
            :importable-type="$options.TYPE_DESIGN"
            class="gl-ml-2"
          />
        </h2>
      </div>
      <close-button class="md:gl-hidden gl-ml-auto" />
    </div>
    <div class="gl-flex md:gl-flex-row gl-flex-shrink-0 gl-md-ml-auto gl-mr-5">
      <gl-button
        v-gl-tooltip.bottom
        category="tertiary"
        class="gl-ml-2"
        :href="design.image"
        icon="download"
        :title="$options.i18n.downloadButtonLabel"
        :aria-label="$options.i18n.downloadButtonLabel"
      />
      <gl-button
        v-gl-tooltip.bottom
        category="tertiary"
        icon="comments"
        :title="toggleCommentsButtonLabel"
        :aria-label="toggleCommentsButtonLabel"
        class="gl-ml-2 gl-mr-5"
        data-testid="toggle-design-sidebar"
        @click="$emit('toggle-sidebar')"
      />
      <design-navigation :filename="designFilename" :all-designs="allDesigns" class="gl-ml-auto" />
    </div>
    <close-button class="gl-hidden md:gl-flex" />
  </header>
</template>
