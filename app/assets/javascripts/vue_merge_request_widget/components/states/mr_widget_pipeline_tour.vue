<script>
import { GlPopover, GlDeprecatedButton, GlSprintf, GlLink } from '@gitlab/ui';
import Icon from '~/vue_shared/components/icon.vue';
import Cookies from 'js-cookie';
import { parseBoolean } from '~/lib/utils/common_utils';
import Tracking from '~/tracking';
import { s__ } from '~/locale';

const trackingMixin = Tracking.mixin();

const cookieKey = 'suggest_pipeline_dismissed';

export default {
  name: 'MRWidgetPipelineTour',
  dismissTrackValue: 20,
  showTrackValue: 10,
  trackEvent: 'click_button',
  helpContent: s__(
    `mrWidget|Use %{linkStart}CI pipelines to test your code%{linkEnd}, simply add a GitLab CI configuration file to your project. It only takes a minute to make your code more secure and robust.`,
  ),
  helpURL: 'https://about.gitlab.com/blog/2019/07/12/guide-to-ci-cd-pipelines/',
  components: {
    GlPopover,
    GlDeprecatedButton,
    Icon,
    GlSprintf,
    GlLink,
  },
  mixins: [trackingMixin],
  props: {
    pipelinePath: {
      type: String,
      required: true,
    },
    pipelineSvgPath: {
      type: String,
      required: true,
    },
    humanAccess: {
      type: String,
      required: true,
    },
    popoverTarget: {
      type: String,
      required: true,
    },
    popoverContainer: {
      type: String,
      required: true,
    },
    trackLabel: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      popoverDismissed: parseBoolean(Cookies.get(cookieKey)),
      tracking: {
        label: this.trackLabel,
        property: this.humanAccess,
      },
    };
  },
  mounted() {
    this.trackOnShow();
  },
  methods: {
    trackOnShow() {
      if (!this.popoverDismissed) {
        this.track();
      }
    },
    dismissPopover() {
      this.popoverDismissed = true;
      Cookies.set(cookieKey, this.popoverDismissed, { expires: 365 });
    },
  },
};
</script>
<template>
  <gl-popover
    v-if="!popoverDismissed"
    show
    :target="popoverTarget"
    :container="popoverContainer"
    placement="rightbottom"
  >
    <template #title>
      <button
        class="btn-blank float-right mt-1"
        type="button"
        :aria-label="__('Close')"
        :data-track-property="humanAccess"
        :data-track-value="$options.dismissTrackValue"
        :data-track-event="$options.trackEvent"
        :data-track-label="trackLabel"
        @click="dismissPopover"
      >
        <icon name="close" aria-hidden="true" />
      </button>
      {{ s__('mrWidget|Are you adding technical debt or code vulnerabilities?') }}
    </template>
    <div class="svg-content svg-150 pt-1">
      <img :src="pipelineSvgPath" />
    </div>
    <gl-sprintf :message="$options.helpContent">
      <template #link="{ content }">
        <gl-link :href="$options.helpURL" target="_blank" class="font-size-inherit">{{
          content
        }}</gl-link>
      </template>
    </gl-sprintf>
    <gl-deprecated-button
      ref="ok"
      category="primary"
      class="mt-2 mb-0"
      variant="info"
      block
      :href="pipelinePath"
      :data-track-property="humanAccess"
      :data-track-value="$options.showTrackValue"
      :data-track-event="$options.trackEvent"
      :data-track-label="trackLabel"
    >
      {{ __('Show me how to add a pipeline') }}
    </gl-deprecated-button>
    <gl-deprecated-button
      ref="no-thanks"
      category="secondary"
      class="mt-2 mb-0"
      variant="info"
      block
      :data-track-property="humanAccess"
      :data-track-value="$options.dismissTrackValue"
      :data-track-event="$options.trackEvent"
      :data-track-label="trackLabel"
      @click="dismissPopover"
    >
      {{ __('No thanks') }}
    </gl-deprecated-button>
  </gl-popover>
</template>
