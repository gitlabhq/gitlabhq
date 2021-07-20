<script>
import {
  GlPath,
  GlPopover,
  GlDeprecatedSkeletonLoading as GlSkeletonLoading,
  GlSafeHtmlDirective as SafeHtml,
} from '@gitlab/ui';
import Tracking from '~/tracking';
import { OVERVIEW_STAGE_ID } from '../constants';
import FormattedStageCount from './formatted_stage_count.vue';

export default {
  name: 'PathNavigation',
  components: {
    GlPath,
    GlSkeletonLoading,
    GlPopover,
    FormattedStageCount,
  },
  directives: {
    SafeHtml,
  },
  mixins: [Tracking.mixin()],
  props: {
    loading: {
      type: Boolean,
      required: false,
      default: false,
    },
    stages: {
      type: Array,
      required: true,
    },
    selectedStage: {
      type: Object,
      required: false,
      default: () => {},
    },
    withStageCounts: {
      type: Boolean,
      required: false,
      default: true,
    },
  },
  methods: {
    showPopover({ id }) {
      return id && id !== OVERVIEW_STAGE_ID;
    },
    onSelectStage($event) {
      this.$emit('selected', $event);
      this.track('click_path_navigation', {
        extra: {
          stage_id: $event.id,
        },
      });
    },
  },
  popoverOptions: {
    triggers: 'hover',
    placement: 'bottom',
  },
};
</script>
<template>
  <gl-skeleton-loading v-if="loading" :lines="2" class="h-auto pt-2 pb-1" />
  <gl-path v-else :key="selectedStage.id" :items="stages" @selected="onSelectStage">
    <template #default="{ pathItem, pathId }">
      <gl-popover
        v-if="showPopover(pathItem)"
        v-bind="$options.popoverOptions"
        :target="pathId"
        :css-classes="['stage-item-popover']"
        data-testid="stage-item-popover"
      >
        <template #title>{{ pathItem.title }}</template>
        <div class="gl-px-4">
          <div class="gl-display-flex gl-justify-content-space-between">
            <div class="gl-pr-4 gl-pb-4">
              {{ s__('ValueStreamEvent|Stage time (median)') }}
            </div>
            <div class="gl-pb-4 gl-font-weight-bold">{{ pathItem.metric }}</div>
          </div>
        </div>
        <div v-if="withStageCounts" class="gl-px-4">
          <div class="gl-display-flex gl-justify-content-space-between">
            <div class="gl-pr-4 gl-pb-4">
              {{ s__('ValueStreamEvent|Items in stage') }}
            </div>
            <div class="gl-pb-4 gl-font-weight-bold">
              <formatted-stage-count :stage-count="pathItem.stageCount" />
            </div>
          </div>
        </div>
        <div class="gl-px-4 gl-pt-4 gl-border-t-1 gl-border-t-solid gl-border-gray-50">
          <div
            v-if="pathItem.startEventHtmlDescription"
            class="gl-display-flex gl-flex-direction-row"
          >
            <div class="gl-display-flex gl-flex-direction-column gl-pr-4 gl-pb-4 metric-label">
              {{ s__('ValueStreamEvent|Start') }}
            </div>
            <div
              v-safe-html="pathItem.startEventHtmlDescription"
              class="gl-display-flex gl-flex-direction-column gl-pb-4 stage-event-description"
            ></div>
          </div>
          <div
            v-if="pathItem.endEventHtmlDescription"
            class="gl-display-flex gl-flex-direction-row"
          >
            <div class="gl-display-flex gl-flex-direction-column gl-pr-4 metric-label">
              {{ s__('ValueStreamEvent|Stop') }}
            </div>
            <div
              v-safe-html="pathItem.endEventHtmlDescription"
              class="gl-display-flex gl-flex-direction-column stage-event-description"
            ></div>
          </div>
        </div>
      </gl-popover>
    </template>
  </gl-path>
</template>
