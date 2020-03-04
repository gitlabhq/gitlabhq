<script>
import { GlPopover, GlSprintf, GlButton, GlIcon } from '@gitlab/ui';
import Cookies from 'js-cookie';
import { parseBoolean } from '~/lib/utils/common_utils';
import { s__ } from '~/locale';
import { glEmojiTag } from '~/emoji';

export default {
  components: {
    GlPopover,
    GlSprintf,
    GlIcon,
    GlButton,
  },
  props: {
    target: {
      type: String,
      required: true,
    },
    cssClass: {
      type: String,
      required: true,
    },
    dismissKey: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      popoverDismissed: parseBoolean(Cookies.get(this.dismissKey)),
    };
  },
  computed: {
    suggestTitle() {
      return s__(`suggestPipeline|1/2: Choose a template`);
    },
    suggestContent() {
      return s__(
        `suggestPipeline|We recommend the %{boldStart}Code Quality%{boldEnd} template, which will add a report widget to your Merge Requests. This way you’ll learn about code quality degradations much sooner. %{footerStart} Goodbye technical debt! %{footerEnd}`,
      );
    },
    emoji() {
      return glEmojiTag('wave');
    },
  },
  methods: {
    onDismiss() {
      this.popoverDismissed = true;
      Cookies.set(this.dismissKey, this.popoverDismissed, { expires: 365 });
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
    :css-classes="[cssClass]"
  >
    <template #title>
      <gl-button :aria-label="__('Close')" class="btn-blank float-right" @click="onDismiss">
        <gl-icon name="close" aria-hidden="true" />
      </gl-button>
      {{ suggestTitle }}
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
