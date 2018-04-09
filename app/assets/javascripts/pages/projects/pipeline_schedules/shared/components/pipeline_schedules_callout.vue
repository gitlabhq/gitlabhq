<script>
  import Vue from 'vue';
  import Cookies from 'js-cookie';
  import Translate from '../../../../../vue_shared/translate';
  import illustrationSvg from '../icons/intro_illustration.svg';

  Vue.use(Translate);

  const cookieKey = 'pipeline_schedules_callout_dismissed';

  export default {
    name: 'PipelineSchedulesCallout',
    data() {
      return {
        docsUrl: document.getElementById('pipeline-schedules-callout').dataset.docsUrl,
        calloutDismissed: Cookies.get(cookieKey) === 'true',
      };
    },
    created() {
      this.illustrationSvg = illustrationSvg;
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
  <div
    v-if="!calloutDismissed"
    class="pipeline-schedules-user-callout user-callout">
    <div class="bordered-box landing content-block">
      <button
        id="dismiss-callout-btn"
        class="btn btn-secondary close"
        @click="dismissCallout">
        <i
          aria-hidden="true"
          class="fa fa-times">
        </i>
      </button>
      <div
        class="svg-container"
        v-html="illustrationSvg">
      </div>
      <div class="user-callout-copy">
        <h4>{{ __('Scheduling Pipelines') }}</h4>
        <p>
          {{ __(`The pipelines schedule runs pipelines in the future,
repeatedly, for specific branches or tags.
Those scheduled pipelines will inherit limited project access based on their associated user.`) }}
        </p>
        <p> {{ __('Learn more in the') }}
          <a
            :href="docsUrl"
            target="_blank"
            rel="nofollow"
          >
          {{ s__('Learn more in the|pipeline schedules documentation') }}</a>.
          <!-- oneline to prevent extra space before period -->
        </p>
      </div>
    </div>
  </div>
</template>
