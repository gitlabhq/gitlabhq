<script>
import _ from 'underscore';
import CiIcon from '~/vue_shared/components/ci_icon.vue';
import Icon from '~/vue_shared/components/icon.vue';

export default {
  components: {
    CiIcon,
    Icon,
  },
  props: {
    pipeline: {
      type: Object,
      required: true,
    },
    stages: {
      type: Array,
      required: true,
    },
    selectedStage: {
      type: String,
      required: true,
    },
  },
  computed: {
    hasRef() {
      return !_.isEmpty(this.pipeline.ref);
    },
  },
  methods: {
    onStageClick(stage) {
      this.$emit('requestSidebarStageDropdown', stage);
    },
  },
};
</script>
<template>
  <div class="block-last dropdown">
    <ci-icon :status="pipeline.details.status" class="vertical-align-middle" />

    <span class="font-weight-bold">{{ __('Pipeline') }}</span>
    <a :href="pipeline.path" class="js-pipeline-path link-commit">#{{ pipeline.id }}</a>
    <template v-if="hasRef">
      {{ __('from') }}
      <a :href="pipeline.ref.path" class="link-commit ref-name">{{ pipeline.ref.name }}</a>
    </template>

    <button
      type="button"
      data-toggle="dropdown"
      class="js-selected-stage dropdown-menu-toggle prepend-top-8"
    >
      {{ selectedStage }} <i class="fa fa-chevron-down"></i>
    </button>

    <ul class="dropdown-menu">
      <li v-for="stage in stages" :key="stage.name">
        <button type="button" class="js-stage-item stage-item" @click="onStageClick(stage);">
          {{ stage.name }}
        </button>
      </li>
    </ul>
  </div>
</template>
