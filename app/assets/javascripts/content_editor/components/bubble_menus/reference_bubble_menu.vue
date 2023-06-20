<script>
import {
  GlTooltipDirective as GlTooltip,
  GlButton,
  GlButtonGroup,
  GlCollapsibleListbox,
} from '@gitlab/ui';
import { __ } from '~/locale';
import Reference from '../../extensions/reference';
import ReferenceLabel from '../../extensions/reference_label';
import EditorStateObserver from '../editor_state_observer.vue';
import BubbleMenu from './bubble_menu.vue';

const REFERENCE_NODE_TYPES = [Reference.name, ReferenceLabel.name];

export default {
  components: {
    BubbleMenu,
    EditorStateObserver,
    GlButton,
    GlCollapsibleListbox,
    GlButtonGroup,
  },
  directives: {
    GlTooltip,
  },
  inject: ['tiptapEditor', 'contentEditor'],
  data() {
    return {
      nodeType: null,

      referenceType: null,
      originalText: null,

      href: null,
      text: null,
      expandedText: null,
      fullyExpandedText: null,

      selectedTextFormat: {},

      loading: false,
    };
  },
  computed: {
    isIssue() {
      return this.referenceType === 'issue';
    },
    isMergeRequest() {
      return this.referenceType === 'merge_request';
    },
    isEpic() {
      return this.referenceType === 'epic';
    },
    isExpandable() {
      return this.isIssue || this.isMergeRequest || this.isEpic;
    },
    textFormats() {
      return [
        {
          value: '',
          text: this.$options.i18n.referenceId[this.referenceType],
          matcher: (text) => !text.endsWith('+') && !text.endsWith('+s'),
          getText: () => this.text,
          shouldShow: true,
        },
        {
          value: '+',
          text: this.$options.i18n.referenceTitle[this.referenceType],
          matcher: (text) => text.endsWith('+'),
          getText: () => this.expandedText,
          shouldShow: true,
        },
        {
          value: '+s',
          text: this.$options.i18n.referenceSummary[this.referenceType],
          matcher: (text) => text.endsWith('+s'),
          getText: () => this.fullyExpandedText,
          shouldShow: this.isIssue || this.isMergeRequest,
        },
      ];
    },
  },
  methods: {
    shouldShow: ({ editor }) => {
      return REFERENCE_NODE_TYPES.some((type) => editor.isActive(type));
    },
    async updateReferenceInfoToState() {
      this.nodeType = REFERENCE_NODE_TYPES.find((type) => this.tiptapEditor.isActive(type));
      if (!this.nodeType) return;

      const {
        referenceType,
        href,
        originalText,
        text: alternateText,
      } = this.tiptapEditor.getAttributes(this.nodeType);

      this.href = href;
      this.referenceType = referenceType;
      this.originalText = originalText || alternateText;
      this.selectedTextFormat = this.textFormats.find(({ matcher }) => matcher(this.originalText));

      this.loading = true;

      const { text, expandedText, fullyExpandedText } = await this.contentEditor.resolveReference(
        this.originalText,
      );

      this.text = text;
      this.expandedText = expandedText;
      this.fullyExpandedText = fullyExpandedText;

      this.loading = false;
    },
    removeReference() {
      this.tiptapEditor.chain().focus().deleteSelection().run();
    },
    copyReferenceURL() {
      navigator.clipboard.writeText(this.href);
    },
    applyFormat(value) {
      const format = this.textFormats.find((v) => v.value === value);

      this.tiptapEditor
        .chain()
        .focus()
        .updateAttributes(this.nodeType, {
          text: format.getText(),
          originalText: `${this.originalText.replace(/(\+|\+s)$/, '')}${format.value}`,
        })
        .run();

      this.selectedTextFormat = format;
    },
  },
  tippyOptions: {
    placement: 'bottom',
  },
  i18n: {
    referenceId: {
      issue: __('Issue ID'),
      merge_request: __('Merge request ID'),
      epic: __('Epic ID'),
    },
    referenceTitle: {
      issue: __('Issue title'),
      merge_request: __('Merge request title'),
      epic: __('Epic title'),
    },
    referenceSummary: {
      issue: __('Issue summary'),
      merge_request: __('Merge request summary'),
      epic: __('Epic summary'),
    },
    copyURLLabel: {
      issue: __('Copy issue URL'),
      merge_request: __('Copy merge request URL'),
      epic: __('Copy epic URL'),
    },
    removeLabel: {
      issue: __('Remove issue reference'),
      merge_request: __('Remove merge request reference'),
      epic: __('Remove epic reference'),
    },
  },
};
</script>
<template>
  <editor-state-observer :debounce="0" @transaction="updateReferenceInfoToState">
    <bubble-menu
      v-show="isExpandable"
      class="gl-shadow gl-rounded-base gl-bg-white"
      plugin-key="bubbleMenuReference"
      :should-show="shouldShow"
      :tippy-options="$options.tippyOptions"
    >
      <gl-button-group class="gl-display-flex gl-align-items-center">
        <span class="gl-py-2 gl-px-3 gl-text-secondary gl-white-space-nowrap">
          {{ __('Display as:') }}
        </span>
        <gl-collapsible-listbox
          v-show="!loading"
          category="tertiary"
          boundary="viewport"
          :selected="selectedTextFormat.value"
          :items="textFormats"
          :loading="loading"
          :toggle-text="selectedTextFormat.text"
          toggle-class="gl-rounded-0!"
          @select="applyFormat"
        />
        <gl-button
          v-gl-tooltip.bottom
          variant="default"
          category="tertiary"
          size="medium"
          data-testid="copy-reference-url"
          :aria-label="$options.i18n.copyURLLabel[referenceType]"
          :title="$options.i18n.copyURLLabel[referenceType]"
          icon="copy-to-clipboard"
          @click="copyReferenceURL"
        />
        <gl-button
          v-gl-tooltip.bottom
          variant="default"
          category="tertiary"
          size="medium"
          data-testid="remove-reference"
          :aria-label="$options.i18n.removeLabel[referenceType]"
          :title="$options.i18n.removeLabel[referenceType]"
          icon="remove"
          @click="removeReference"
        />
      </gl-button-group>
    </bubble-menu>
  </editor-state-observer>
</template>
