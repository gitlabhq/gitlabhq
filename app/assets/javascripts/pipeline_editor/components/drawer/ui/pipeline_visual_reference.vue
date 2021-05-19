<script>
import { s__ } from '~/locale';
import DemoJobPill from './demo_job_pill.vue';

export default {
  i18n: {
    stageNames: {
      build: s__('StageName|Build'),
      test: s__('StageName|Test'),
      deploy: s__('StageName|Deploy'),
    },
    jobNames: {
      build: s__('JobName|build-job'),
      test_1: s__('JobName|unit-test'),
      test_2: s__('JobName|lint-test'),
      deploy: s__('JobName|deploy-app'),
    },
  },
  stageClasses:
    'gl-bg-blue-50 gl-display-flex gl-flex-direction-column gl-align-items-center gl-p-4 gl-rounded-base',
  titleClasses: 'gl-text-blue-600 gl-mb-4',
  components: {
    DemoJobPill,
  },
};
</script>
<template>
  <div class="gl-display-flex gl-justify-content-center">
    <div :class="$options.stageClasses" class="gl-mr-5">
      <div :class="$options.titleClasses">{{ $options.i18n.stageNames.build }}</div>
      <demo-job-pill :job-name="$options.i18n.jobNames.build" />
    </div>
    <div :class="$options.stageClasses" class="gl-mr-5">
      <div :class="$options.titleClasses">{{ $options.i18n.stageNames.test }}</div>
      <demo-job-pill class="gl-mb-3" :job-name="$options.i18n.jobNames.test_1" />
      <demo-job-pill :job-name="$options.i18n.jobNames.test_2" />
    </div>
    <div :class="$options.stageClasses">
      <div :class="$options.titleClasses">{{ $options.i18n.stageNames.deploy }}</div>
      <demo-job-pill :job-name="$options.i18n.jobNames.deploy" />
    </div>
  </div>
</template>
