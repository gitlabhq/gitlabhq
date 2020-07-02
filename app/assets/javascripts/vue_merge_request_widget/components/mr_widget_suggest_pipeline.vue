<script>
import { GlLink, GlSprintf, GlButton } from '@gitlab/ui';
import MrWidgetIcon from './mr_widget_icon.vue';
import Tracking from '~/tracking';
import { s__ } from '~/locale';

const trackingMixin = Tracking.mixin();
const TRACK_LABEL = 'no_pipeline_noticed';

export default {
  name: 'MRWidgetSuggestPipeline',
  iconName: 'status_notfound',
  trackLabel: TRACK_LABEL,
  linkTrackValue: 30,
  linkTrackEvent: 'click_link',
  showTrackValue: 10,
  showTrackEvent: 'click_button',
  helpContent: s__(
    `mrWidget|Use %{linkStart}CI pipelines to test your code%{linkEnd} by simply adding a GitLab CI configuration file to your project. It only takes a minute to make your code more secure and robust.`,
  ),
  helpURL: 'https://about.gitlab.com/blog/2019/07/12/guide-to-ci-cd-pipelines/',
  components: {
    GlLink,
    GlSprintf,
    GlButton,
    MrWidgetIcon,
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
  },
  computed: {
    tracking() {
      return {
        label: TRACK_LABEL,
        property: this.humanAccess,
      };
    },
  },
  mounted() {
    this.track();
  },
};
</script>
<template>
  <div class="mr-widget-body mr-pipeline-suggest gl-mb-3">
    <div class="gl-display-flex gl-align-items-center">
      <mr-widget-icon :name="$options.iconName" />
      <div>
        <gl-sprintf
          :message="
            s__(`mrWidget|%{prefixToLinkStart}No pipeline%{prefixToLinkEnd}
          %{addPipelineLinkStart}Add the .gitlab-ci.yml file%{addPipelineLinkEnd}
          to create one.`)
          "
        >
          <template #prefixToLink="{content}">
            <strong>
              {{ content }}
            </strong>
          </template>
          <template #addPipelineLink="{content}">
            <gl-link
              :href="pipelinePath"
              class="gl-ml-1"
              data-testid="add-pipeline-link"
              :data-track-property="humanAccess"
              :data-track-value="$options.linkTrackValue"
              :data-track-event="$options.linkTrackEvent"
              :data-track-label="$options.trackLabel"
            >
              {{ content }}
            </gl-link>
          </template>
        </gl-sprintf>
      </div>
    </div>
    <div class="row">
      <div class="col-md-5 order-md-last col-12 gl-mt-5 mt-md-n3 svg-content svg-225">
        <img data-testid="pipeline-image" :src="pipelineSvgPath" />
      </div>
      <div class="col-md-7 order-md-first col-12">
        <div class="ml-6 gl-pt-5">
          <strong>
            {{ s__('mrWidget|Are you adding technical debt or code vulnerabilities?') }}
          </strong>
          <p class="gl-mt-2">
            <gl-sprintf :message="$options.helpContent">
              <template #link="{ content }">
                <gl-link
                  data-testid="help"
                  :href="$options.helpURL"
                  target="_blank"
                  class="font-size-inherit"
                  >{{ content }}
                </gl-link>
              </template>
            </gl-sprintf>
          </p>
          <gl-button
            data-testid="ok"
            category="primary"
            class="gl-mt-2"
            variant="info"
            :href="pipelinePath"
            :data-track-property="humanAccess"
            :data-track-value="$options.showTrackValue"
            :data-track-event="$options.showTrackEvent"
            :data-track-label="$options.trackLabel"
          >
            {{ __('Show me how to add a pipeline') }}
          </gl-button>
        </div>
      </div>
    </div>
  </div>
</template>
