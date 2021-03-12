<script>
import { GlButton } from '@gitlab/ui';
import { helpPagePath } from '~/helpers/help_page_helper';
import { s__ } from '~/locale';

export default {
  i18n: {
    infoMessage: s__(`Pipelines|GitLab CI/CD can automatically build,
          test, and deploy your code. Let GitLab take care of time
          consuming tasks, so you can spend more time creating.`),
    buttonMessage: s__('Pipelines|Get started with CI/CD'),
  },
  name: 'PipelinesEmptyState',
  components: {
    GlButton,
  },
  props: {
    emptyStateSvgPath: {
      type: String,
      required: true,
    },
    canSetCi: {
      type: Boolean,
      required: true,
    },
  },
  computed: {
    ciHelpPagePath() {
      return helpPagePath('ci/quick_start/index.md');
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
            {{ $options.i18n.infoMessage }}
          </p>

          <div class="gl-text-center">
            <gl-button
              :href="ciHelpPagePath"
              variant="info"
              category="primary"
              data-testid="get-started-pipelines"
            >
              {{ $options.i18n.buttonMessage }}
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
