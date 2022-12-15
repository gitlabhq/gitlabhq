<script>
import { GlSkeletonLoader } from '@gitlab/ui';
import { s__ } from '~/locale';
import SystemNote from '~/work_items/components/notes/system_note.vue';
import { i18n, DEFAULT_PAGE_SIZE_NOTES } from '~/work_items/constants';
import { getWorkItemNotesQuery } from '~/work_items/utils';

export default {
  i18n: {
    ACTIVITY_LABEL: s__('WorkItem|Activity'),
  },
  loader: {
    repeat: 10,
    width: 1000,
    height: 40,
  },
  components: {
    SystemNote,
    GlSkeletonLoader,
  },
  props: {
    workItemId: {
      type: String,
      required: true,
    },
    queryVariables: {
      type: Object,
      required: true,
    },
    fullPath: {
      type: String,
      required: true,
    },
    fetchByIid: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    areNotesLoading() {
      return this.$apollo.queries.workItemNotes.loading;
    },
    notes() {
      return this.workItemNotes?.nodes;
    },
    pageInfo() {
      return this.workItemNotes?.pageInfo;
    },
  },
  apollo: {
    workItemNotes: {
      query() {
        return getWorkItemNotesQuery(this.fetchByIid);
      },
      context: {
        isSingleRequest: true,
      },
      variables() {
        return {
          ...this.queryVariables,
          pageSize: DEFAULT_PAGE_SIZE_NOTES,
        };
      },
      update(data) {
        const workItemWidgets = this.fetchByIid
          ? data.workspace?.workItems?.nodes[0]?.widgets
          : data.workItem?.widgets;
        return workItemWidgets.find((widget) => widget.type === 'NOTES').discussions || [];
      },
      skip() {
        return !this.queryVariables.id && !this.queryVariables.iid;
      },
      error() {
        this.$emit('error', i18n.fetchError);
      },
    },
  },
};
</script>

<template>
  <div class="gl-border-t gl-mt-5">
    <label class="gl-mb-0">{{ $options.i18n.ACTIVITY_LABEL }}</label>
    <div v-if="areNotesLoading" class="gl-mt-5">
      <gl-skeleton-loader
        v-for="index in $options.loader.repeat"
        :key="index"
        :width="$options.loader.width"
        :height="$options.loader.height"
        preserve-aspect-ratio="xMinYMax meet"
      >
        <circle cx="20" cy="20" r="16" />
        <rect width="500" x="45" y="15" height="10" rx="4" />
      </gl-skeleton-loader>
    </div>
    <div v-else class="issuable-discussion gl-mb-5 work-item-notes">
      <template v-if="notes && notes.length">
        <ul class="notes main-notes-list timeline">
          <system-note
            v-for="note in notes"
            :key="note.notes.nodes[0].id"
            :note="note.notes.nodes[0]"
          />
        </ul>
      </template>
    </div>
  </div>
</template>
