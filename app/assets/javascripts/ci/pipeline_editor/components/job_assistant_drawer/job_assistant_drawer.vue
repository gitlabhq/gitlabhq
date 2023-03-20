<script>
import { GlDrawer, GlAccordion, GlButton } from '@gitlab/ui';
import { stringify, parse } from 'yaml';
import { set, omit, trim } from 'lodash';
import { getContentWrapperHeight } from '~/lib/utils/dom_utils';
import eventHub, { SCROLL_EDITOR_TO_BOTTOM } from '~/ci/pipeline_editor/event_hub';
import getAllRunners from '~/ci/runner/graphql/list/all_runners.query.graphql';
import { DRAWER_CONTAINER_CLASS, JOB_TEMPLATE, i18n } from './constants';
import { removeEmptyObj, trimFields } from './utils';
import JobSetupItem from './accordion_items/job_setup_item.vue';
import ImageItem from './accordion_items/image_item.vue';

export default {
  i18n,
  components: {
    GlDrawer,
    GlAccordion,
    GlButton,
    JobSetupItem,
    ImageItem,
  },
  props: {
    isVisible: {
      type: Boolean,
      required: false,
      default: false,
    },
    zIndex: {
      type: Number,
      required: false,
      default: 200,
    },
    ciConfigData: {
      type: Object,
      required: true,
    },
    ciFileContent: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      isNameValid: true,
      isScriptValid: true,
      job: JSON.parse(JSON.stringify(JOB_TEMPLATE)),
    };
  },
  apollo: {
    runners: {
      query: getAllRunners,
      update(data) {
        return data?.runners?.nodes || [];
      },
    },
  },
  computed: {
    availableStages() {
      if (this.ciConfigData?.mergedYaml) {
        return parse(this.ciConfigData.mergedYaml).stages;
      }
      return [];
    },
    tagOptions() {
      const options = [];
      this.runners?.forEach((runner) => options.push(...runner.tagList));
      return [...new Set(options)].map((tag) => {
        return {
          id: tag,
          name: tag,
        };
      });
    },
    drawerHeightOffset() {
      return getContentWrapperHeight(DRAWER_CONTAINER_CLASS);
    },
  },
  methods: {
    closeDrawer() {
      this.clearJob();
      this.$emit('close-job-assistant-drawer');
    },
    addCiConfig() {
      this.isNameValid = this.validate(this.job.name);
      this.isScriptValid = this.validate(this.job.script);

      if (!this.isNameValid || !this.isScriptValid) {
        return;
      }

      const newJobString = this.generateYmlString();
      this.$emit('updateCiConfig', `${this.ciFileContent}\n${newJobString}`);
      eventHub.$emit(SCROLL_EDITOR_TO_BOTTOM);

      this.closeDrawer();
    },
    generateYmlString() {
      let job = JSON.parse(JSON.stringify(this.job));
      const jobName = job.name;
      job = omit(job, ['name']);
      job.tags = job.tags.map((tag) => tag.name); // Tag item is originally an option object, we need a string here to match `.gitlab-ci.yml` rules
      const cleanedJob = trimFields(removeEmptyObj(job));
      return stringify({ [jobName]: cleanedJob });
    },
    clearJob() {
      this.job = JSON.parse(JSON.stringify(JOB_TEMPLATE));
      this.isNameValid = true;
      this.isScriptValid = true;
    },
    updateJob(key, value) {
      set(this.job, key, value);
      if (key === 'name') {
        this.isNameValid = this.validate(this.job.name);
      }
      if (key === 'script') {
        this.isScriptValid = this.validate(this.job.script);
      }
    },
    validate(value) {
      return trim(value) !== '';
    },
  },
};
</script>
<template>
  <gl-drawer
    class="job-assistant-drawer"
    :header-height="drawerHeightOffset"
    :open="isVisible"
    :z-index="zIndex"
    @close="closeDrawer"
  >
    <template #title>
      <h2 class="gl-m-0 gl-font-lg">{{ $options.i18n.ADD_JOB }}</h2>
    </template>
    <gl-accordion :header-level="3">
      <job-setup-item
        :tag-options="tagOptions"
        :job="job"
        :is-name-valid="isNameValid"
        :is-script-valid="isScriptValid"
        :available-stages="availableStages"
        @update-job="updateJob"
      />
      <image-item :job="job" @update-job="updateJob" />
    </gl-accordion>
    <template #footer>
      <div class="gl-display-flex gl-justify-content-end">
        <gl-button
          category="primary"
          class="gl-mr-3"
          data-testid="cancel-button"
          @click="closeDrawer"
          >{{ __('Cancel') }}
        </gl-button>
        <gl-button
          category="primary"
          variant="confirm"
          data-testid="confirm-button"
          @click="addCiConfig"
          >{{ __('Add') }}
        </gl-button>
      </div>
    </template>
  </gl-drawer>
</template>
