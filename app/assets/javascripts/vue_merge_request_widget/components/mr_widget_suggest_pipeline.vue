<script>
import { GlLink, GlSprintf } from '@gitlab/ui';
import MrWidgetIcon from './mr_widget_icon.vue';

export default {
  name: 'MRWidgetSuggestPipeline',
  iconName: 'status_notfound',
  components: {
    GlLink,
    GlSprintf,
    MrWidgetIcon,
  },
  props: {
    pipelinePath: {
      type: String,
      required: true,
    },
  },
};
</script>
<template>
  <div class="d-flex mr-pipeline-suggest append-bottom-default">
    <mr-widget-icon :name="$options.iconName" />
    <gl-sprintf
      class="js-no-pipeline-message"
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
        <gl-link :href="pipelinePath" class="ml-2">
          {{ content }}
        </gl-link>
        &nbsp;
      </template>
    </gl-sprintf>
  </div>
</template>
