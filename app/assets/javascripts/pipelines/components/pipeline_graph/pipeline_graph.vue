<script>
import { isEmpty } from 'lodash';
import { GlAlert } from '@gitlab/ui';
import JobPill from './job_pill.vue';
import StagePill from './stage_pill.vue';

export default {
  components: {
    GlAlert,
    JobPill,
    StagePill,
  },
  props: {
    pipelineData: {
      required: true,
      type: Object,
    },
  },
  computed: {
    isPipelineDataEmpty() {
      return isEmpty(this.pipelineData);
    },
    emptyClass() {
      return !this.isPipelineDataEmpty ? 'gl-py-7' : '';
    },
  },
};
</script>
<template>
  <div class="gl-display-flex gl-bg-gray-50 gl-px-4 gl-overflow-auto" :class="emptyClass">
    <gl-alert v-if="isPipelineDataEmpty" variant="tip" :dismissible="false">
      {{ __('No content to show') }}
    </gl-alert>
    <template v-else>
      <div
        v-for="(stage, index) in pipelineData.stages"
        :key="`${stage.name}-${index}`"
        class="gl-flex-direction-column"
      >
        <div
          class="gl-display-flex gl-align-items-center gl-bg-white gl-w-full gl-px-8 gl-py-4 gl-mb-5"
          :class="{
            'stage-left-rounded': index === 0,
            'stage-right-rounded': index === pipelineData.stages.length - 1,
          }"
        >
          <stage-pill :stage-name="stage.name" :is-empty="stage.groups.length === 0" />
        </div>
        <div
          class="gl-display-flex gl-flex-direction-column gl-align-items-center gl-w-full gl-px-8"
        >
          <job-pill v-for="group in stage.groups" :key="group.name" :job-name="group.name" />
        </div>
      </div>
    </template>
  </div>
</template>
