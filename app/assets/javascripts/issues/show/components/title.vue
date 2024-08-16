<!-- eslint-disable vue/multi-word-component-names -->
<script>
import { GlTooltipDirective } from '@gitlab/ui';
import SafeHtml from '~/vue_shared/directives/safe_html';
import animateMixin from '../mixins/animate';

export default {
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
  },
};
</script>

<template>
  <div class="gl-flex gl-flex-col gl-items-start gl-gap-3 gl-pt-3 md:gl-flex-row">
    <h1
      v-safe-html="titleHtml"
      :class="{
        'issue-realtime-pre-pulse': preAnimation,
        'issue-realtime-trigger-pulse': pulseAnimation,
      }"
      class="title gl-heading-1 !gl-m-0"
      data-testid="issue-title"
      dir="auto"
    ></h1>
    <slot name="actions"></slot>
  </div>
</template>
