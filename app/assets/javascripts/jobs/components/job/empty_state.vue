<script>
import { GlLink } from '@gitlab/ui';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import LegacyManualVariablesForm from '~/jobs/components/job/legacy_manual_variables_form.vue';
import ManualVariablesForm from '~/jobs/components/job/manual_variables_form.vue';

export default {
  components: {
    GlLink,
    LegacyManualVariablesForm,
    ManualVariablesForm,
  },
  mixins: [glFeatureFlagsMixin()],
  props: {
    illustrationPath: {
      type: String,
      required: true,
    },
    illustrationSizeClass: {
      type: String,
      required: true,
    },
    title: {
      type: String,
      required: true,
    },
    content: {
      type: String,
      required: false,
      default: null,
    },
    playable: {
      type: Boolean,
      required: true,
      default: false,
    },
    scheduled: {
      type: Boolean,
      required: false,
      default: false,
    },
    action: {
      type: Object,
      required: false,
      default: null,
      validator(value) {
        return (
          value === null ||
          (Object.prototype.hasOwnProperty.call(value, 'path') &&
            Object.prototype.hasOwnProperty.call(value, 'method') &&
            Object.prototype.hasOwnProperty.call(value, 'button_title'))
        );
      },
    },
  },
  computed: {
    isGraphQL() {
      return this.glFeatures?.graphqlJobApp;
    },
    shouldRenderManualVariables() {
      return this.playable && !this.scheduled;
    },
  },
};
</script>
<template>
  <div class="row empty-state">
    <div class="col-12">
      <div :class="illustrationSizeClass" class="svg-content">
        <img :src="illustrationPath" />
      </div>
    </div>

    <div class="col-12">
      <div class="text-content">
        <h4 class="text-center" data-testid="job-empty-state-title">{{ title }}</h4>

        <p v-if="content" data-testid="job-empty-state-content">{{ content }}</p>
      </div>
      <template v-if="isGraphQL">
        <manual-variables-form v-if="shouldRenderManualVariables" :action="action" />
      </template>
      <template v-else>
        <legacy-manual-variables-form v-if="shouldRenderManualVariables" :action="action" />
      </template>
      <div class="text-content">
        <div v-if="action && !shouldRenderManualVariables" class="text-center">
          <gl-link
            :href="action.path"
            :data-method="action.method"
            class="btn gl-button btn-confirm gl-text-decoration-none!"
            data-testid="job-empty-state-action"
            >{{ action.button_title }}</gl-link
          >
        </div>
      </div>
    </div>
  </div>
</template>
