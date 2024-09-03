<script>
import { GlDrawer, GlAccordion, GlButton } from '@gitlab/ui';
import { stringify, parse } from 'yaml';
import { get, omit, toPath } from 'lodash';
import { DRAWER_Z_INDEX } from '~/lib/utils/constants';
import { getContentWrapperHeight } from '~/lib/utils/dom_utils';
import eventHub, { SCROLL_EDITOR_TO_BOTTOM } from '~/ci/pipeline_editor/event_hub';
import { EDITOR_APP_DRAWER_NONE } from '~/ci/pipeline_editor/constants';
import getRunnerTags from '../../graphql/queries/runner_tags.query.graphql';
import { JOB_TEMPLATE, JOB_RULES_WHEN, i18n } from './constants';
import { removeEmptyObj, trimFields, validateEmptyValue, validateStartIn } from './utils';
import JobSetupItem from './accordion_items/job_setup_item.vue';
import ImageItem from './accordion_items/image_item.vue';
import ServicesItem from './accordion_items/services_item.vue';
import ArtifactsAndCacheItem from './accordion_items/artifacts_and_cache_item.vue';
import RulesItem from './accordion_items/rules_item.vue';

export default {
  i18n,
  components: {
    GlDrawer,
    GlAccordion,
    GlButton,
    JobSetupItem,
    ImageItem,
    ServicesItem,
    ArtifactsAndCacheItem,
    RulesItem,
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
      default: DRAWER_Z_INDEX,
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
      isStartValid: true,
      job: JSON.parse(JSON.stringify(JOB_TEMPLATE)),
    };
  },
  apollo: {
    // eslint-disable-next-line @gitlab/vue-no-undef-apollo-properties
    runners: {
      query: getRunnerTags,
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
    getDrawerHeaderHeight() {
      return getContentWrapperHeight();
    },
    isJobValid() {
      return this.isNameValid && this.isScriptValid && this.isStartValid;
    },
  },

  watch: {
    'job.name': function jobNameWatch(name) {
      this.isNameValid = validateEmptyValue(name);
    },
    'job.script': function jobScriptWatch(script) {
      this.isScriptValid = validateEmptyValue(script);
    },
    'job.rules.0.start_in': function JobRulesStartInWatch(startIn) {
      this.isStartValid = validateStartIn(this.job.rules[0].when, startIn);
    },
  },
  methods: {
    closeDrawer() {
      this.clearJob();
      this.$emit('switch-drawer', EDITOR_APP_DRAWER_NONE);
    },
    addCiConfig() {
      this.validateJob();

      if (!this.isJobValid) {
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
      job = this.removeUnnecessaryKeys(job);
      job.tags = job.tags.map((tag) => tag.name); // Tag item is originally an option object, we need a string here to match `.gitlab-ci.yml` rules
      const cleanedJob = trimFields(removeEmptyObj(job));
      return stringify({ [jobName]: cleanedJob });
    },
    removeUnnecessaryKeys(job) {
      const keys = ['name'];

      // rules[0].allow_failure value should not be passed down
      // if it equals the default value
      if (this.job.rules[0].allow_failure === false) {
        keys.push('rules[0].allow_failure');
      }
      // rules[0].when value should not be passed down
      // if it equals the default value
      if (this.job.rules[0].when === JOB_RULES_WHEN.onSuccess.value) {
        keys.push('rules[0].when');
      }
      // rules[0].start_in value should not be passed down
      // if rules[0].start_in doesn't equal 'delayed'
      if (this.job.rules[0].when !== JOB_RULES_WHEN.delayed.value) {
        keys.push('rules[0].start_in');
      }
      return omit(job, keys);
    },
    clearJob() {
      this.job = JSON.parse(JSON.stringify(JOB_TEMPLATE));
      this.$nextTick(() => {
        this.isNameValid = true;
        this.isScriptValid = true;
        this.isStartValid = true;
      });
    },
    updateJob(key, value) {
      const path = toPath(key);
      const targetObj = path.length === 1 ? this.job : get(this.job, path.slice(0, -1));
      const lastKey = path[path.length - 1];
      if (value !== undefined) {
        targetObj[lastKey] = value;
      } else {
        delete targetObj[lastKey];
      }
    },
    validateJob() {
      this.isNameValid = validateEmptyValue(this.job.name);
      this.isScriptValid = validateEmptyValue(this.job.script);
      this.isStartValid = validateStartIn(this.job.rules[0].when, this.job.rules[0].start_in);
    },
  },
};
</script>
<template>
  <gl-drawer
    class="job-assistant-drawer"
    :header-height="getDrawerHeaderHeight"
    :open="isVisible"
    :z-index="zIndex"
    @close="closeDrawer"
  >
    <template #title>
      <h2 class="gl-m-0 gl-text-lg">{{ $options.i18n.ADD_JOB }}</h2>
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
      <services-item :job="job" @update-job="updateJob" />
      <artifacts-and-cache-item :job="job" @update-job="updateJob" />
      <rules-item :job="job" :is-start-valid="isStartValid" @update-job="updateJob" />
    </gl-accordion>
    <template #footer>
      <div class="gl-flex gl-justify-end">
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
