<script>
import { GlPath, GlPopover, GlSkeletonLoader } from '@gitlab/ui';
import SafeHtml from '~/vue_shared/directives/safe_html';
import Tracking from '~/tracking';
import { OVERVIEW_STAGE_ID } from '../constants';
import FormattedStageCount from './formatted_stage_count.vue';

export default {
  name: 'PathNavigation',
  components: {
    GlPath,
    GlSkeletonLoader,
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
      default: () => ({}),
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
};
</script>
<template>
  <gl-skeleton-loader v-if="loading" :width="235" :lines="2" />
  <gl-path v-else :key="selectedStage.id" :items="stages" @selected="onSelectStage">
    <template #default="{ pathItem, pathId }">
      <gl-popover
        v-if="showPopover(pathItem)"
        placement="bottom"
        :target="pathId"
        :css-classes="['stage-item-popover']"
        data-testid="stage-item-popover"
      >
        <template #title>{{ pathItem.title }}</template>
        <div class="gl-px-4">
          <div class="gl-flex gl-justify-between">
            <div class="gl-pb-3 gl-pr-4">
              {{ s__('ValueStreamEvent|Stage time (median)') }}
            </div>
            <div class="gl-pb-3 gl-font-bold">{{ pathItem.metric }}</div>
          </div>
        </div>
        <div class="gl-px-4">
          <div class="gl-flex gl-justify-between">
            <div class="gl-pb-3 gl-pr-4">
              {{ s__('ValueStreamEvent|Items in stage') }}
            </div>
            <div class="gl-pb-3 gl-font-bold">
              <formatted-stage-count :stage-count="pathItem.stageCount" />
            </div>
          </div>
        </div>
        <div class="gl-px-4">
          <div class="gl-pb-3 gl-italic">
            {{ s__('ValueStreamEvent|Only items that reached their stop event.') }}
          </div>
        </div>
        <div class="gl-border-t-1 gl-border-subtle gl-px-4 gl-pt-4 gl-border-t-solid">
          <div v-if="pathItem.startEventHtmlDescription" class="gl-flex gl-flex-row">
            <div class="metric-label gl-flex gl-flex-col gl-pb-3 gl-pr-4">
              {{ s__('ValueStreamEvent|Start') }}
            </div>
            <div
              v-safe-html="pathItem.startEventHtmlDescription"
              class="stage-event-description gl-flex gl-flex-col gl-pb-3"
            ></div>
          </div>
          <div v-if="pathItem.endEventHtmlDescription" class="gl-flex gl-flex-row">
            <div class="metric-label gl-flex gl-flex-col gl-pr-4">
              {{ s__('ValueStreamEvent|Stop') }}
            </div>
            <div
              v-safe-html="pathItem.endEventHtmlDescription"
              class="stage-event-description gl-flex gl-flex-col"
            ></div>
          </div>
        </div>
      </gl-popover>
    </template>
  </gl-path>
</template>
