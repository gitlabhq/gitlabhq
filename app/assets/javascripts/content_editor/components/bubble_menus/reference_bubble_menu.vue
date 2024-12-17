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
import { REFERENCE_TYPES } from '../../constants/reference_types';
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
    isWorkItem() {
      return this.referenceType === REFERENCE_TYPES.WORK_ITEM;
    },
    isIssue() {
      return this.referenceType === REFERENCE_TYPES.ISSUE;
    },
    isMergeRequest() {
      return this.referenceType === REFERENCE_TYPES.MERGE_REQUEST;
    },
    isEpic() {
      return this.referenceType === REFERENCE_TYPES.EPIC;
    },
    isExpandable() {
      return this.isIssue || this.isWorkItem || this.isMergeRequest || this.isEpic;
    },
    showSummary() {
      return !this.isEpic;
    },
    textFormats() {
      return [
        {
          value: '',
          text: this.$options.i18n.referenceId,
          matcher: (text) => !text.endsWith('+') && !text.endsWith('+s'),
          getText: () => this.text,
          shouldShow: true,
        },
        {
          value: '+',
          text: this.$options.i18n.referenceTitle,
          matcher: (text) => text.endsWith('+'),
          getText: () => this.expandedText,
          shouldShow: true,
        },
        {
          value: '+s',
          text: this.$options.i18n.referenceSummary,
          matcher: (text) => text.endsWith('+s'),
          getText: () => this.fullyExpandedText,
          shouldShow: this.showSummary,
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
    referenceId: __('ID'),
    referenceTitle: __('Title'),
    referenceSummary: __('Summary'),
    copyURLLabel: __('Copy URL'),
    removeLabel: __('Remove reference'),
  },
};
</script>
<template>
  <editor-state-observer :debounce="0" @transaction="updateReferenceInfoToState">
    <bubble-menu
      v-show="isExpandable"
      class="gl-rounded-base gl-bg-white gl-shadow"
      plugin-key="bubbleMenuReference"
      :should-show="shouldShow"
      :tippy-options="$options.tippyOptions"
    >
      <gl-button-group class="gl-flex gl-items-center">
        <span class="gl-whitespace-nowrap gl-px-3 gl-py-2 gl-text-subtle">
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
          toggle-class="!gl-rounded-none"
          @select="applyFormat"
        />
        <gl-button
          v-gl-tooltip.bottom
          variant="default"
          category="tertiary"
          size="medium"
          data-testid="copy-reference-url"
          :aria-label="$options.i18n.copyURLLabel"
          :title="$options.i18n.copyURLLabel"
          icon="copy-to-clipboard"
          @click="copyReferenceURL"
        />
        <gl-button
          v-gl-tooltip.bottom
          variant="default"
          category="tertiary"
          size="medium"
          data-testid="remove-reference"
          :aria-label="$options.i18n.removeLabel"
          :title="$options.i18n.removeLabel"
          icon="remove"
          @click="removeReference"
        />
      </gl-button-group>
    </bubble-menu>
  </editor-state-observer>
</template>
