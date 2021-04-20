<script>
import { GlPopover, GlSprintf, GlButton } from '@gitlab/ui';
import { parseBoolean, scrollToElement, setCookie, getCookie } from '~/lib/utils/common_utils';
import { s__ } from '~/locale';
import Tracking from '~/tracking';

const trackingMixin = Tracking.mixin();

const popoverStates = {
  suggest_gitlab_ci_yml: {
    title: s__(`suggestPipeline|1/2: Choose a template`),
    content: s__(
      `suggestPipeline|We’re adding a GitLab CI configuration file to add a pipeline to the project. You could create it manually, but we recommend that you start with a GitLab template that works out of the box.`,
    ),
    footer: s__(
      `suggestPipeline|Choose %{boldStart}Code Quality%{boldEnd} to add a pipeline that tests the quality of your code.`,
    ),
  },
  suggest_commit_first_project_gitlab_ci_yml: {
    title: s__(`suggestPipeline|2/2: Commit your changes`),
    content: s__(
      `suggestPipeline|The template is ready! You can now commit it to create your first pipeline.`,
    ),
  },
};
export default {
  dismissTrackValue: 10,
  clickTrackValue: 'click_button',
  components: {
    GlPopover,
    GlSprintf,
    GlButton,
  },
  mixins: [trackingMixin],
  props: {
    target: {
      type: String,
      required: true,
    },
    trackLabel: {
      type: String,
      required: true,
    },
    dismissKey: {
      type: String,
      required: true,
    },
    humanAccess: {
      type: String,
      required: true,
    },
    mergeRequestPath: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      popoverDismissed: parseBoolean(getCookie(`${this.trackLabel}_${this.dismissKey}`)),
      tracking: {
        label: this.trackLabel,
        property: this.humanAccess,
      },
    };
  },
  computed: {
    suggestTitle() {
      return popoverStates[this.trackLabel].title || '';
    },
    suggestContent() {
      return popoverStates[this.trackLabel].content || '';
    },
    suggestFooter() {
      return popoverStates[this.trackLabel].footer || '';
    },
    emoji() {
      return popoverStates[this.trackLabel].emoji || '';
    },
    dismissCookieName() {
      return `${this.trackLabel}_${this.dismissKey}`;
    },
  },
  mounted() {
    if (
      this.trackLabel === 'suggest_commit_first_project_gitlab_ci_yml' &&
      !this.popoverDismissed
    ) {
      scrollToElement(document.querySelector(this.target));
    }

    this.trackOnShow();
  },
  methods: {
    onDismiss() {
      this.popoverDismissed = true;
      setCookie(this.dismissCookieName, this.popoverDismissed);
    },
    trackOnShow() {
      if (!this.popoverDismissed) this.track();
    },
  },
};
</script>

<template>
  <gl-popover
    v-if="!popoverDismissed"
    show
    :target="target"
    placement="right"
    container="viewport"
    :css-classes="['suggest-gitlab-ci-yml', 'ml-4']"
  >
    <template #title>
      <span>{{ suggestTitle }}</span>
      <span class="ml-auto">
        <gl-button
          :aria-label="__('Close')"
          class="btn-blank"
          name="dismiss"
          icon="close"
          :data-track-property="humanAccess"
          :data-track-value="$options.dismissTrackValue"
          :data-track-event="$options.clickTrackValue"
          :data-track-label="trackLabel"
          @click="onDismiss"
        />
      </span>
    </template>

    <gl-sprintf :message="suggestContent" />
    <div class="mt-3">
      <gl-sprintf :message="suggestFooter">
        <template #bold="{ content }">
          <strong> {{ content }} </strong>
        </template>
      </gl-sprintf>
    </div>
  </gl-popover>
</template>
