<script>
import Vue from 'vue';
import Cookies from 'js-cookie';
import { GlButton } from '@gitlab/ui';
import Translate from '../../../../../vue_shared/translate';
import { parseBoolean } from '~/lib/utils/common_utils';

Vue.use(Translate);

const cookieKey = 'pipeline_schedules_callout_dismissed';

export default {
  name: 'PipelineSchedulesCallout',
  components: {
    GlButton,
  },
  inject: ['docsUrl', 'illustrationUrl'],
  data() {
    return {
      calloutDismissed: parseBoolean(Cookies.get(cookieKey)),
    };
  },
  methods: {
    dismissCallout() {
      this.calloutDismissed = true;
      Cookies.set(cookieKey, this.calloutDismissed, { expires: 365 });
    },
  },
};
</script>
<template>
  <div v-if="!calloutDismissed" class="pipeline-schedules-user-callout user-callout">
    <div class="bordered-box landing content-block" data-testid="innerContent">
      <gl-button
        category="tertiary"
        icon="close"
        :aria-label="__('Dismiss')"
        class="gl-absolute gl-top-2 gl-right-2"
        @click="dismissCallout"
      />
      <div class="svg-content">
        <img :src="illustrationUrl" />
      </div>
      <div class="user-callout-copy">
        <h4>{{ __('Scheduling Pipelines') }}</h4>
        <p>
          {{
            __(`The pipelines schedule runs pipelines in the future,
repeatedly, for specific branches or tags.
Those scheduled pipelines will inherit limited project access based on their associated user.`)
          }}
        </p>
        <p>
          {{ __('Learn more in the') }}
          <a :href="docsUrl" target="_blank" rel="nofollow">
            {{ s__('Learn more in the|pipeline schedules documentation') }}</a
          >.
          <!-- oneline to prevent extra space before period -->
        </p>
      </div>
    </div>
  </div>
</template>
