<script>
import { GlButton, GlIcon, GlSkeletonLoader, GlTooltipDirective } from '@gitlab/ui';
import { isLoggedIn } from '~/lib/utils/common_utils';
import { TYPE_DESIGN } from '~/import/constants';
import { s__ } from '~/locale';
import ImportedBadge from '~/vue_shared/components/imported_badge.vue';
import TodosToggle from '../../shared/todos_toggle.vue';
import ArchiveDesignButton from '../archive_design_button.vue';
import CloseButton from './close_button.vue';
import DesignNavigation from './design_navigation.vue';

export default {
  i18n: {
    downloadButtonLabel: s__('DesignManagement|Download design'),
    hideCommentsButtonLabel: s__('DesignManagement|Hide comments'),
    showCommentsButtonLabel: s__('DesignManagement|Show comments'),
    archiveButtonLabel: s__('DesignManagement|Archive design'),
  },
  isLoggedIn: isLoggedIn(),
  components: {
    GlButton,
    GlIcon,
    GlSkeletonLoader,
    ImportedBadge,
    CloseButton,
    DesignNavigation,
    TodosToggle,
    ArchiveDesignButton,
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
    isLatestVersion: {
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
    currentUserDesignTodos: {
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
    class="js-design-header gl-border-b gl-flex gl-max-w-full gl-flex-col gl-justify-between gl-bg-white gl-py-4 gl-pl-5 md:gl-flex-row md:gl-items-center"
  >
    <div class="gl-mb-3 gl-flex gl-flex-row gl-items-center gl-overflow-hidden md:gl-mb-0">
      <div class="gl-mr-3 gl-flex gl-overflow-hidden">
        <gl-skeleton-loader v-if="isLoading" :lines="1" />
        <h2 v-else class="gl-m-0 gl-flex gl-items-center gl-overflow-hidden gl-text-base">
          <span class="gl-truncate gl-text-heading gl-no-underline">
            {{ workItemTitle }}
          </span>
          <gl-icon name="chevron-right" class="gl-shrink-0" variant="disabled" />
          <span class="gl-truncate gl-font-normal">{{ design.filename }}</span>
          <imported-badge
            v-if="design.imported"
            :importable-type="$options.TYPE_DESIGN"
            class="gl-ml-2"
          />
        </h2>
      </div>
      <close-button class="gl-ml-auto md:gl-hidden" />
    </div>
    <div
      v-if="!isLoading && design.id"
      class="gl-mr-5 gl-flex gl-shrink-0 md:gl-ml-auto md:gl-flex-row"
    >
      <todos-toggle
        v-if="$options.isLoggedIn"
        :item-id="design.id"
        :current-user-todos="currentUserDesignTodos"
        todos-button-type="tertiary"
        @todosUpdated="$emit('todosUpdated', $event)"
      />
      <gl-button
        v-gl-tooltip.bottom
        category="tertiary"
        class="gl-ml-2"
        :href="design.image"
        icon="download"
        :title="$options.i18n.downloadButtonLabel"
        :aria-label="$options.i18n.downloadButtonLabel"
      />
      <archive-design-button
        v-if="isLatestVersion"
        v-gl-tooltip.bottom
        button-size="medium"
        :title="$options.i18n.archiveButtonLabel"
        :aria-label="$options.i18n.archiveButtonLabel"
        button-icon="archive"
        class="gl-ml-2"
        button-category="tertiary"
        @archive-selected-designs="$emit('archive-design')"
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
