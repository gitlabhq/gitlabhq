<script>
import { GlButton, GlPopover, GlLink } from '@gitlab/ui';
import UserCalloutDismisser from '~/vue_shared/components/user_callout_dismisser.vue';
import { __ } from '~/locale';
import RICH_TEXT_EDITOR_ILLUSTRATION from '../../../../images/callouts/rich_text_editor_illustration.svg?url';
import { counter } from './utils';

export default {
  components: {
    GlButton,
    GlLink,
    GlPopover,
    UserCalloutDismisser,
  },
  props: {
    value: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      counter: counter(),
    };
  },
  computed: {
    showPromoPopover() {
      return this.markdownEditorSelected && this.counter === 0;
    },
    markdownEditorSelected() {
      return this.value === 'markdown';
    },
    text() {
      return this.markdownEditorSelected
        ? __('Switch to rich text editing')
        : __('Switch to plain text editing');
    },
  },
  methods: {
    switchEditorType(insertTemplate = false) {
      this.$emit('switch', insertTemplate);
    },
  },
  richTextEditorButtonId: 'switch-to-rich-text-editor',
  RICH_TEXT_EDITOR_ILLUSTRATION,
};
</script>
<template>
  <div class="content-editor-switcher gl-display-inline-flex gl-align-items-center">
    <user-callout-dismisser feature-name="rich_text_editor">
      <template #default="{ dismiss, shouldShowCallout }">
        <div>
          <gl-popover
            :target="$options.richTextEditorButtonId"
            :show="Boolean(showPromoPopover && shouldShowCallout)"
            show-close-button
            :css-classes="['rich-text-promo-popover gl-p-2']"
            triggers="manual"
            data-testid="rich-text-promo-popover"
            @close-button-clicked="dismiss"
          >
            <img
              :src="$options.RICH_TEXT_EDITOR_ILLUSTRATION"
              :alt="''"
              class="rich-text-promo-popover-illustration"
              width="280"
              height="130"
            />
            <h5 class="gl-mt-3 gl-mb-3">{{ __('Writing just got easier') }}</h5>
            <p class="gl-m-0">
              {{
                __(
                  'Use the new rich text editor to see your text and tables fully formatted as you type. No need to remember any formatting syntax, or switch between preview and editing modes!',
                )
              }}
            </p>
            <gl-link
              class="gl-button btn btn-confirm block gl-mb-2 gl-mt-4"
              variant="confirm"
              category="primary"
              target="_blank"
              block
              @click="
                switchEditorType(showPromoPopover);
                dismiss();
              "
            >
              {{ __('Try the rich text editor now') }}
            </gl-link>
          </gl-popover>
          <gl-button
            :id="$options.richTextEditorButtonId"
            class="btn btn-default btn-sm gl-button btn-default-tertiary gl-font-sm! gl-text-secondary! gl-px-4!"
            data-qa-selector="editing_mode_switcher"
            @click="
              switchEditorType();
              dismiss();
            "
            >{{ text }}</gl-button
          >
        </div>
      </template>
    </user-callout-dismisser>
  </div>
</template>
<style>
.rich-text-promo-popover {
  box-shadow: 0 0 18px -1.9px rgba(119, 89, 194, 0.16), 0 0 12.9px -1.7px rgba(119, 89, 194, 0.16),
    0 0 9.2px -1.4px rgba(119, 89, 194, 0.16), 0 0 6.4px -1.1px rgba(119, 89, 194, 0.16),
    0 0 4.5px -0.8px rgba(119, 89, 194, 0.16), 0 0 3px -0.6px rgba(119, 89, 194, 0.16),
    0 0 1.8px -0.3px rgba(119, 89, 194, 0.16), 0 0 0.6px rgba(119, 89, 194, 0.16);
  z-index: 999;
}

.rich-text-promo-popover-illustration {
  width: calc(100% + 32px);
  margin: -32px -16px 0;
}
</style>
