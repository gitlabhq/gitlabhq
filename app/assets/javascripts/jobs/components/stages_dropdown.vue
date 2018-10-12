<script>
<<<<<<< HEAD
  import _ from 'underscore';
  import CiIcon from '~/vue_shared/components/ci_icon.vue';
  import Icon from '~/vue_shared/components/icon.vue';
  import { __ } from '~/locale';
=======
import _ from 'underscore';
import CiIcon from '~/vue_shared/components/ci_icon.vue';
import Icon from '~/vue_shared/components/icon.vue';
>>>>>>> 7e342757e28... Merge branch '52618-incorrect-stage-being-shown-in-side-bar-of-job-view-api' into 'master'

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
    },
<<<<<<< HEAD
    data() {
      return {
        selectedStage: this.stages.length > 0 ? this.stages[0].name : __('More'),
      };
    },
    computed: {
      hasRef() {
        return !_.isEmpty(this.pipeline.ref);
      },
    },
    watch: {
      // When the component is initially mounted it may start with an empty stages array.
      // Once the prop is updated, we set the first stage as the selected one
      stages(newVal) {
        if (newVal.length) {
          this.selectedStage = newVal[0].name;
        }
      },
=======
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
>>>>>>> 7e342757e28... Merge branch '52618-incorrect-stage-being-shown-in-side-bar-of-job-view-api' into 'master'
    },
    methods: {
      onStageClick(stage) {
        this.$emit('requestSidebarStageDropdown', stage);
        this.selectedStage = stage.name;
      },
    },
  };
</script>
<template>
  <div class="block-last dropdown">
    <ci-icon
      :status="pipeline.details.status"
      class="vertical-align-middle"
    />

    {{ __('Pipeline') }}
    <a
      :href="pipeline.path"
      class="js-pipeline-path link-commit"
    >
      #{{ pipeline.id }}
    </a>
    <template v-if="hasRef">
      {{ __('from') }}
      <a
        :href="pipeline.ref.path"
        class="link-commit ref-name"
      >
        {{ pipeline.ref.name }}
      </a>
    </template>

    <button
      type="button"
      data-toggle="dropdown"
      class="js-selected-stage dropdown-menu-toggle prepend-top-8"
    >
      {{ selectedStage }}
      <i class="fa fa-chevron-down" ></i>
    </button>

    <ul class="dropdown-menu">
      <li
        v-for="stage in stages"
        :key="stage.name"
      >
        <button
          type="button"
          class="js-stage-item stage-item"
          @click="onStageClick(stage)"
        >
          {{ stage.name }}
        </button>
      </li>
    </ul>
  </div>
</template>
