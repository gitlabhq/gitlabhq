<script>
import { GlPopover, GlSprintf, GlButton, GlIcon } from '@gitlab/ui';
import Cookies from 'js-cookie';
import { parseBoolean, scrollToElement } from '~/lib/utils/common_utils';
import { s__ } from '~/locale';
import { glEmojiTag } from '~/emoji';
import Tracking from '~/tracking';

const trackingMixin = Tracking.mixin();

const popoverStates = {
  suggest_gitlab_ci_yml: {
    title: s__(`suggestPipeline|1/2: Choose a template`),
    content: s__(
      `suggestPipeline|We recommend the %{boldStart}Code Quality%{boldEnd} template, which will add a report widget to your Merge Requests. This way you’ll learn about code quality degradations much sooner. %{footerStart} Goodbye technical debt! %{footerEnd}`,
    ),
    emoji: glEmojiTag('wave'),
  },
  suggest_commit_first_project_gitlab_ci_yml: {
    title: s__(`suggestPipeline|2/2: Commit your changes`),
    content: s__(
      `suggestPipeline|Commit the changes and your pipeline will automatically run for the first time.`,
    ),
  },
};
export default {
  components: {
    GlPopover,
    GlSprintf,
    GlIcon,
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
  },
  data() {
    return {
      popoverDismissed: parseBoolean(Cookies.get(this.dismissKey)),
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
    emoji() {
      return popoverStates[this.trackLabel].emoji || '';
    },
  },
  mounted() {
    if (this.trackLabel === 'suggest_commit_first_project_gitlab_ci_yml' && !this.popoverDismissed)
      scrollToElement(document.querySelector(this.target));

    this.trackOnShow();
  },
  methods: {
    onDismiss() {
      this.popoverDismissed = true;
      Cookies.set(this.dismissKey, this.popoverDismissed, { expires: 365 });
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
    placement="rightbottom"
    trigger="manual"
    container="viewport"
    :css-classes="['suggest-gitlab-ci-yml', 'ml-4']"
  >
    <template #title>
      <span v-html="suggestTitle"></span>
      <span class="ml-auto">
        <gl-button :aria-label="__('Close')" class="btn-blank" @click="onDismiss">
          <gl-icon name="close" aria-hidden="true" />
        </gl-button>
      </span>
    </template>

    <gl-sprintf :message="suggestContent">
      <template #bold="{content}">
        <strong> {{ content }} </strong>
      </template>
      <template #footer="{content}">
        <div class="mt-3">
          {{ content }}
          <span v-html="emoji"></span>
        </div>
      </template>
    </gl-sprintf>
  </gl-popover>
</template>
