<script>
import WorkItemNotesLoading from '~/work_items/components/notes/work_item_notes_loading.vue';

export default {
  name: 'WorkItemLoading',
  loader: {
    attributesRepeat: 6,
  },
  components: {
    WorkItemNotesLoading,
  },
};
</script>

<template>
  <div>
    <div class="gl-mb-5" data-testid="work-title-and-meta-loading">
      <div
        class="gl-animate-skeleton-loader gl-mb-2 gl-h-8 gl-w-88 gl-max-w-full gl-rounded-base"
      ></div>
      <div class="gl-flex gl-items-center gl-gap-3">
        <div class="gl-animate-skeleton-loader gl-my-2 gl-h-6 gl-w-11 gl-rounded-pill"></div>
        <div class="gl-animate-skeleton-loader gl-my-2 gl-h-4 gl-w-13 gl-rounded-base"></div>
      </div>
    </div>
    <div class="work-item-overview" data-testid="work-item-two-column-loading">
      <section>
        <!--- START work item description -->
        <div class="gl-mb-6 gl-mt-5" data-testid="work-item-description-loading">
          <div
            v-for="i in 4"
            :key="i"
            class="gl-animate-skeleton-loader gl-my-3 gl-h-4 gl-max-w-full gl-rounded-base"
          ></div>
          <div
            class="gl-animate-skeleton-loader gl-my-3 gl-h-4 gl-max-w-[95%] gl-rounded-base"
          ></div>
        </div>
        <!--- END work item description -->

        <div
          class="work-item-attributes-wrapper gl-my-6 md:!gl-hidden"
          data-testid="work-item-attributes-xssm-loading"
        >
          <div v-for="i in $options.loader.attributesRepeat" :key="i">
            <div
              class="gl-animate-skeleton-loader gl-my-3 gl-h-3 gl-max-w-[20%] gl-rounded-base"
            ></div>
            <div
              class="gl-animate-skeleton-loader gl-mb-7 gl-h-4 gl-max-w-full gl-rounded-base"
            ></div>
          </div>
        </div>
        <!--- END work item attributes wrapper small/xs screen -->

        <!--- START work item notes activity placeholder -->
        <div
          class="gl-animate-skeleton-loader gl-my-6 gl-h-7 gl-w-20 gl-max-w-full gl-rounded-base"
          data-testid="work-item-activity-placeholder-loading"
        ></div>

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
          <div v-for="i in $options.loader.attributesRepeat" :key="i">
            <div
              class="gl-animate-skeleton-loader gl-my-3 gl-h-3 gl-max-w-[20%] gl-rounded-base"
            ></div>
            <div
              class="gl-animate-skeleton-loader gl-mb-7 gl-h-4 gl-max-w-full gl-rounded-base"
            ></div>
          </div>
        </div>
      </aside>
      <!--- END work item attributes wrapper md/lg screens -->
    </div>
  </div>
</template>
