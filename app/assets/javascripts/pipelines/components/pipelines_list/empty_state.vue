<script>
import { GlButton } from '@gitlab/ui';

export default {
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
};
</script>
<template>
  <div class="row empty-state js-empty-state">
    <div class="col-12">
      <div class="svg-content svg-250"><img :src="emptyStateSvgPath" /></div>
    </div>

    <div class="col-12">
      <div class="gl-text-content">
        <template v-if="canSetCi">
          <h4 class="gl-text-center" data-testid="header-text">
            {{ s__('Pipelines|Build with confidence') }}
          </h4>

          <p data-testid="info-text">
            {{
              s__(`Pipelines|Continuous Integration can help
                catch bugs by running your tests automatically,
                while Continuous Deployment can help you deliver
                code to your product environment.`)
            }}
          </p>

          <div class="gl-text-center">
            <gl-button
              :href="helpPagePath"
              variant="info"
              category="primary"
              data-testid="get-started-pipelines"
            >
              {{ s__('Pipelines|Get started with Pipelines') }}
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
