<!-- eslint-disable vue/multi-word-component-names -->
<script>
import { GlPopover } from '@gitlab/ui';
import SafeHtml from '~/vue_shared/directives/safe_html';

const newPopover = (element) => {
  const { content, html, placement, title, triggers = 'focus' } = element.dataset;

  return {
    target: element,
    content,
    html,
    placement,
    title,
    triggers,
  };
};

export default {
  components: {
    GlPopover,
  },
  directives: {
    SafeHtml,
  },
  data() {
    return {
      popovers: [],
    };
  },
  created() {
    this.observer = new MutationObserver((mutations) => {
      mutations.forEach((mutation) => {
        mutation.removedNodes.forEach(this.dispose);
      });
    });
  },
  beforeDestroy() {
    this.observer.disconnect();
  },
  methods: {
    addPopovers(elements) {
      const newPopovers = elements.reduce((acc, element) => {
        if (this.popoverExists(element)) {
          return acc;
        }
        const popover = newPopover(element);
        this.observe(popover);
        return [...acc, popover];
      }, []);

      this.popovers.push(...newPopovers);
    },
    observe(popover) {
      this.observer.observe(popover.target.parentElement, {
        childList: true,
      });
    },
    dispose(target) {
      if (!target) {
        this.popovers = [];
      } else {
        const index = this.popovers.findIndex((popover) => popover.target === target);

        if (index > -1) {
          this.popovers.splice(index, 1);
        }
      }
    },
    popoverExists(element) {
      return this.popovers.some((popover) => popover.target === element);
    },
  },
  safeHtmlConfig: {
    ADD_TAGS: ['use'], // to support icon SVGs
  },
};
</script>

<template>
  <div>
    <gl-popover v-for="(popover, index) in popovers" :key="index" v-bind="popover">
      <template v-if="popover.title" #title>
        <span v-if="popover.html" v-safe-html:[$options.safeHtmlConfig]="popover.title"></span>
        <span v-else>{{ popover.title }}</span>
      </template>
      <span v-if="popover.html" v-safe-html:[$options.safeHtmlConfig]="popover.content"></span>
      <span v-else>{{ popover.content }}</span>
    </gl-popover>
  </div>
</template>
