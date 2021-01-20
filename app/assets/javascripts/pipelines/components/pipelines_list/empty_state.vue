<script>
import { GlButton } from '@gitlab/ui';
import { isExperimentEnabled } from '~/lib/utils/experimentation';
import { s__ } from '~/locale';
import Tracking from '~/tracking';

export default {
  i18n: {
    control: {
      infoMessage: s__(`Pipelines|Continuous Integration can help
        catch bugs by running your tests automatically,
        while Continuous Deployment can help you deliver
        code to your product environment.`),
      buttonMessage: s__('Pipelines|Get started with Pipelines'),
    },
    experiment: {
      infoMessage: s__(`Pipelines|GitLab CI/CD can automatically build,
          test, and deploy your code. Let GitLab take care of time
          consuming tasks, so you can spend more time creating.`),
      buttonMessage: s__('Pipelines|Get started with CI/CD'),
    },
  },
  name: 'PipelinesEmptyState',
  components: {
    GlButton,
  },
  props: {
    helpPagePath: {
      type: String,
      required: true,
    },
    emptyStateSvgPath: {
      type: String,
      required: true,
    },
    canSetCi: {
      type: Boolean,
      required: true,
    },
  },
  mounted() {
    this.track('viewed');
  },
  methods: {
    track(action) {
      if (!gon.tracking_data) {
        return;
      }

      const { category, value, label, property } = gon.tracking_data;

      Tracking.event(category, action, { value, label, property });
    },
    isExperimentEnabled() {
      return isExperimentEnabled('pipelinesEmptyState');
    },
  },
};
</script>
<template>
  <div class="row empty-state js-empty-state">
    <div class="col-12">
      <div class="svg-content svg-250"><img :src="emptyStateSvgPath" /></div>
    </div>

    <div class="col-12">
      <div class="text-content">
        <template v-if="canSetCi">
          <h4 data-testid="header-text" class="gl-text-center">
            {{ s__('Pipelines|Build with confidence') }}
          </h4>
          <p data-testid="info-text">
            {{
              isExperimentEnabled()
                ? $options.i18n.experiment.infoMessage
                : $options.i18n.control.infoMessage
            }}
          </p>

          <div class="gl-text-center">
            <gl-button
              :href="helpPagePath"
              variant="info"
              category="primary"
              data-testid="get-started-pipelines"
              @click="track('documentation_clicked')"
            >
              {{
                isExperimentEnabled()
                  ? $options.i18n.experiment.buttonMessage
                  : $options.i18n.control.buttonMessage
              }}
            </gl-button>
          </div>
        </template>

        <p v-else class="gl-text-center">
          {{ s__('Pipelines|This project is not currently set up to run pipelines.') }}
        </p>
      </div>
    </div>
  </div>
</template>
