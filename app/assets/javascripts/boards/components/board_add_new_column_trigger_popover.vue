<script>
import { GlButton, GlPopover } from '@gitlab/ui';
import { s__ } from '~/locale';
import UserCalloutDismisser from '~/vue_shared/components/user_callout_dismisser.vue';
import { glEmojiTag } from '~/emoji';
import SafeHtml from '~/vue_shared/directives/safe_html';

export default {
  name: 'BoardAddNewColumnTriggerPopover',
  components: {
    GlButton,
    GlPopover,
    UserCalloutDismisser,
  },
  directives: {
    SafeHtml,
  },
  data() {
    return {
      emoji: glEmojiTag('sparkles'),
    };
  },
  mounted() {
    setTimeout(() => {
      const popover = this.$refs.boardNewListButtonCallout;
      this.$emit('boardAddNewColumnTriggerPopoverRendered', popover);
    }, 1000);
  },
  i18n: {
    title: s__('Boards|The "New list" button has moved'),
    body: s__('Boards|You can add a new list to the board here'),
    dismiss: s__('Boards|Got it'),
  },
  safeHtmlConfig: { ADD_TAGS: ['gl-emoji'] },
};
</script>

<template>
  <user-callout-dismisser feature-name="board_add_new_column_trigger_popover">
    <template #default="{ dismiss, shouldShowCallout, isAnonUser }">
      <gl-popover
        v-if="shouldShowCallout && !isAnonUser"
        ref="boardNewListButtonCallout"
        :show="shouldShowCallout"
        :css-classes="[
          'gl-max-w-48',
          'gl-shadow-lg',
          'gl-p-2',
          'gl-bg-blue-50',
          'board-new-list-button-callout',
        ]"
        target="boards-create-list"
        triggers="manual"
        placement="left"
        data-testid="board-new-list-button-callout"
      >
        <h5 class="gl-mt-0 gl-mb-3">
          {{ $options.i18n.title }}
          <span v-safe-html:[$options.safeHtmlConfig]="emoji" class="gl-ml-2"></span>
        </h5>

        <p class="gl-my-2 gl-font-base">
          {{ $options.i18n.body }}
        </p>
        <div class="gl-display-flex gl-justify-content-end gl-mt-4 gl-mb-2">
          <gl-button
            variant="confirm"
            category="secondary"
            class="gl-bg-transparent!"
            data-testid="board-new-list-button-callout-dismiss"
            @click="dismiss"
            >{{ $options.i18n.dismiss }}</gl-button
          >
        </div>
      </gl-popover>
    </template>
  </user-callout-dismisser>
</template>
<style lang="scss">
.board-new-list-button-callout {
  z-index: 9;
  &.bs-popover-left .arrow::after {
    border-left-color: var(--blue-50, #e9f3fc) !important;
  }
  &.bs-popover-right > .arrow::after {
    border-right-color: var(--blue-50, #e9f3fc) !important;
  }
  &.bs-popover-bottom > .arrow::after {
    border-bottom-color: var(--blue-50, #e9f3fc) !important;
  }
  &.bs-popover-top > .arrow::after {
    border-top-color: var(--blue-50, #e9f3fc) !important;
  }
}
</style>
