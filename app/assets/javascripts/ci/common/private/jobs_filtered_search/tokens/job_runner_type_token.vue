<script>
import { GlFilteredSearchToken, GlFilteredSearchSuggestion, GlIcon } from '@gitlab/ui';
import { s__ } from '~/locale';
import {
  JOB_RUNNER_TYPE_INSTANCE_TYPE,
  JOB_RUNNER_TYPE_GROUP_TYPE,
  JOB_RUNNER_TYPE_PROJECT_TYPE,
} from '../constants';

export default {
  components: {
    GlFilteredSearchToken,
    GlFilteredSearchSuggestion,
    GlIcon,
  },
  props: {
    config: {
      type: Object,
      required: true,
    },
    value: {
      type: Object,
      required: true,
    },
  },
  computed: {
    runnerTypes() {
      return [
        {
          class: 'ci-runner-runner-type-instance',
          icon: 'users',
          text: s__('Runners|Instance'),
          value: JOB_RUNNER_TYPE_INSTANCE_TYPE,
        },
        {
          class: 'ci-runner-runner-type-group',
          icon: 'group',
          text: s__('Runners|Group'),
          value: JOB_RUNNER_TYPE_GROUP_TYPE,
        },
        {
          class: 'ci-runner-runner-type-project',
          icon: 'project',
          text: s__('Runners|Project'),
          value: JOB_RUNNER_TYPE_PROJECT_TYPE,
        },
      ];
    },
    findActiveRunnerType() {
      return this.runnerTypes.find((runnerType) => runnerType.value === this.value.data);
    },
  },
};
</script>

<template>
  <gl-filtered-search-token v-bind="{ ...$props, ...$attrs }" v-on="$listeners">
    <template #view>
      <div class="gl-flex gl-items-center">
        <div :class="findActiveRunnerType.class">
          <gl-icon :name="findActiveRunnerType.icon" class="gl-mr-2 gl-block" />
        </div>
        <span>{{ findActiveRunnerType.text }}</span>
      </div>
    </template>
    <template #suggestions>
      <gl-filtered-search-suggestion
        v-for="(runnerType, index) in runnerTypes"
        :key="index"
        :value="runnerType.value"
      >
        <div class="gl-flex" :class="runnerType.class">
          <gl-icon :name="runnerType.icon" class="gl-mr-3" />
          <span>{{ runnerType.text }}</span>
        </div>
      </gl-filtered-search-suggestion>
    </template>
  </gl-filtered-search-token>
</template>
