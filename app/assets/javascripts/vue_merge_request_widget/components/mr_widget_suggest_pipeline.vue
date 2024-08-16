<script>
import { GlLink, GlSprintf, GlButton } from '@gitlab/ui';
import Tracking from '~/tracking';
import DismissibleContainer from '~/vue_shared/components/dismissible_container.vue';
import {
  SP_TRACK_LABEL,
  SP_SHOW_TRACK_EVENT,
  SP_SHOW_TRACK_VALUE,
  SP_HELP_CONTENT,
  SP_HELP_URL,
  SP_ICON_NAME,
} from '../constants';
import MrWidgetIcon from './mr_widget_icon.vue';

const trackingMixin = Tracking.mixin();

export default {
  name: 'MRWidgetSuggestPipeline',
  SP_ICON_NAME,
  SP_TRACK_LABEL,
  SP_SHOW_TRACK_EVENT,
  SP_SHOW_TRACK_VALUE,
  SP_HELP_CONTENT,
  SP_HELP_URL,
  components: {
    GlLink,
    GlSprintf,
    GlButton,
    MrWidgetIcon,
    DismissibleContainer,
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
    userCalloutsPath: {
      type: String,
      required: true,
    },
    userCalloutFeatureId: {
      type: String,
      required: true,
    },
  },
  computed: {
    tracking() {
      return {
        label: SP_TRACK_LABEL,
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
  <dismissible-container
    class="mr-widget-body mr-pipeline-suggest gl-mb-3"
    :path="userCalloutsPath"
    :feature-id="userCalloutFeatureId"
    @dismiss="$emit('dismiss')"
  >
    <template #title>
      <mr-widget-icon :name="$options.SP_ICON_NAME" />
      <div>
        <gl-sprintf
          :message="
            s__(`mrWidget|%{boldHeaderStart}Looks like there's no pipeline here.%{boldHeaderEnd}`)
          "
        >
          <template #boldHeader="{ content }">
            <strong>
              {{ content }}
            </strong>
          </template>
        </gl-sprintf>
      </div>
    </template>
    <div class="row">
      <div
        class="col-md-5 order-md-last col-12 svg-content svg-225 gl-mt-5 md:!-gl-mt-2 md:gl-pt-2"
      >
        <img data-testid="pipeline-image" :src="pipelineSvgPath" />
      </div>
      <div class="col-md-7 order-md-first col-12">
        <div class="ml-6 gl-pt-5">
          <p class="gl-mt-2">
            <gl-sprintf :message="$options.SP_HELP_CONTENT">
              <template #link="{ content }">
                <gl-link data-testid="help" :href="$options.SP_HELP_URL" target="_blank"
                  >{{ content }}
                </gl-link>
              </template>
            </gl-sprintf>
          </p>
          <gl-button
            data-testid="ok"
            category="primary"
            class="gl-mt-2"
            variant="confirm"
            :href="pipelinePath"
            :data-track-property="humanAccess"
            :data-track-value="$options.SP_SHOW_TRACK_VALUE"
            :data-track-action="$options.SP_SHOW_TRACK_EVENT"
            :data-track-label="$options.SP_TRACK_LABEL"
          >
            {{ __('Try out GitLab Pipelines') }}
          </gl-button>
        </div>
      </div>
    </div>
  </dismissible-container>
</template>
