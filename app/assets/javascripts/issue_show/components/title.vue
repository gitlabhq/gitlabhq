<script>
import { GlButton, GlTooltipDirective, GlSafeHtmlDirective as SafeHtml } from '@gitlab/ui';
import animateMixin from '../mixins/animate';
import eventHub from '../event_hub';

export default {
  components: {
    GlButton,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
    SafeHtml,
  },
  mixins: [animateMixin],
  props: {
    issuableRef: {
      type: [String, Number],
      required: true,
    },
    canUpdate: {
      required: false,
      type: Boolean,
      default: false,
    },
    titleHtml: {
      type: String,
      required: true,
    },
    titleText: {
      type: String,
      required: true,
    },
    showInlineEditButton: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      preAnimation: false,
      pulseAnimation: false,
      titleEl: document.querySelector('title'),
    };
  },
  watch: {
    titleHtml() {
      this.setPageTitle();
      this.animateChange();
    },
  },
  methods: {
    setPageTitle() {
      const currentPageTitleScope = this.titleEl.innerText.split('·');
      currentPageTitleScope[0] = `${this.titleText} (${this.issuableRef}) `;
      this.titleEl.textContent = currentPageTitleScope.join('·');
    },
    edit() {
      eventHub.$emit('open.form');
    },
  },
};
</script>

<template>
  <div class="title-container">
    <h2
      v-safe-html="titleHtml"
      :class="{
        'issue-realtime-pre-pulse': preAnimation,
        'issue-realtime-trigger-pulse': pulseAnimation,
      }"
      class="title qa-title"
      dir="auto"
    ></h2>
    <gl-button
      v-if="showInlineEditButton && canUpdate"
      v-gl-tooltip.bottom
      icon="pencil"
      class="btn-edit js-issuable-edit qa-edit-button"
      title="Edit title and description"
      @click="edit"
    />
  </div>
</template>
