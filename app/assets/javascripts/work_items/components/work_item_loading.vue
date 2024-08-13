<script>
import { GlSkeletonLoader } from '@gitlab/ui';
import WorkItemNotesLoading from '~/work_items/components/notes/work_item_notes_loading.vue';

export default {
  name: 'WorkItemLoading',
  loader: {
    descriptionRepeat: 2,
    attributesRepeat: 6,
  },
  components: {
    GlSkeletonLoader,
    WorkItemNotesLoading,
  },
};
</script>

<template>
  <div class="work-item-overview" data-testid="work-item-two-column-loading">
    <section>
      <gl-skeleton-loader :height="60" :width="600" data-testid="work-title-and-meta-loading">
        <!--- START work item title -->
        <rect width="500" height="20" x="5" y="0" rx="4" />
        <!--- END work item title -->
        <!--- START work item meta -->
        <rect width="50" height="15" x="5" y="30" rx="6" />
        <rect width="150" height="5" x="60" y="35" rx="2" />
        <!--- END work item meta -->
      </gl-skeleton-loader>

      <!--- START work item description -->
      <div data-testid="work-item-description-loading">
        <gl-skeleton-loader
          v-for="i in $options.loader.descriptionRepeat"
          :key="i"
          :width="600"
          :height="20"
        >
          <rect width="500" x="5" y="0" height="5" rx="2" />
          <rect width="595" x="5" y="10" height="5" rx="2" />
        </gl-skeleton-loader>

        <gl-skeleton-loader :width="600" :height="20">
          <rect width="300" x="5" y="0" height="5" rx="2" />
        </gl-skeleton-loader>

        <gl-skeleton-loader :width="600" :height="20">
          <rect width="500" x="5" y="0" height="5" rx="2" />
          <rect width="595" x="5" y="10" height="5" rx="2" />
        </gl-skeleton-loader>

        <gl-skeleton-loader :width="600" :height="20">
          <rect width="300" x="5" y="0" height="5" rx="2" />
        </gl-skeleton-loader>
      </div>
      <!--- END work item description -->

      <!--- START work item attributes wrapper small/xs screen -->
      <div
        class="work-item-attributes-wrapper md:!gl-hidden"
        data-testid="work-item-attributes-xssm-loading"
      >
        <gl-skeleton-loader
          v-for="i in $options.loader.attributesRepeat"
          :key="i"
          :width="240"
          :height="20"
        >
          <rect width="50" x="2" y="0" height="2" rx="1" />
          <rect width="100" x="2" y="5" height="4" rx="1" />
        </gl-skeleton-loader>
      </div>
      <!--- END work item attributes wrapper small/xs screen -->

      <!--- START work item notes activity placeholder -->
      <gl-skeleton-loader
        :height="30"
        :width="600"
        data-testid="work-item-activity-placeholder-loading"
      >
        <rect width="100" height="15" x="5" y="0" rx="4" />
      </gl-skeleton-loader>
      <!--- END work item notes activity placeholder -->

      <!--- START work item notes -->
      <work-item-notes-loading />
      <!--- END work item notes -->
    </section>

    <!--- START work item attributes wrapper md/lg screens -->
    <aside
      class="work-item-overview-right-sidebar gl-hidden md:!gl-block"
      data-testid="work-item-attributes-mdup-loading"
    >
      <div class="work-item-attributes-wrapper">
        <gl-skeleton-loader
          v-for="i in $options.loader.attributesRepeat"
          :key="i"
          :width="240"
          :height="50"
        >
          <rect width="100" x="0" y="25" height="5" rx="4" />
          <rect width="240" x="0" y="35" height="10" rx="4" />
        </gl-skeleton-loader>
      </div>
    </aside>
    <!--- END work item attributes wrapper md/lg screens -->
  </div>
</template>
