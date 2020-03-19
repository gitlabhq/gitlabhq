<script>
import { GlLink, GlSprintf } from '@gitlab/ui';
import MrWidgetIcon from './mr_widget_icon.vue';
import PipelineTourState from './states/mr_widget_pipeline_tour.vue';

export default {
  name: 'MRWidgetSuggestPipeline',
  iconName: 'status_notfound',
  popoverTarget: 'suggest-popover',
  popoverContainer: 'suggest-pipeline',
  trackLabel: 'no_pipeline_noticed',
  linkTrackValue: 30,
  linkTrackEvent: 'click_link',
  components: {
    GlLink,
    GlSprintf,
    MrWidgetIcon,
    PipelineTourState,
  },
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
};
</script>
<template>
  <div :id="$options.popoverContainer" class="d-flex mr-pipeline-suggest append-bottom-default">
    <mr-widget-icon :name="$options.iconName" />
    <div :id="$options.popoverTarget">
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
            class="ml-2 js-add-pipeline-path"
            :data-track-property="humanAccess"
            :data-track-value="$options.linkTrackValue"
            :data-track-event="$options.linkTrackEvent"
            :data-track-label="$options.trackLabel"
          >
            {{ content }}
          </gl-link>
        </template>
      </gl-sprintf>
      <pipeline-tour-state
        :pipeline-path="pipelinePath"
        :pipeline-svg-path="pipelineSvgPath"
        :human-access="humanAccess"
        :popover-target="$options.popoverTarget"
        :popover-container="$options.popoverContainer"
        :track-label="$options.trackLabel"
      />
    </div>
  </div>
</template>
