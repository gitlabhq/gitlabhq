<script>
// We can't use v-safe-html here as the popover's title or content might contains SVGs that would
// be stripped by the directive's sanitizer. Instead, we fallback on v-html and we use GitLab's
// dompurify config that lets SVGs be rendered properly.
// Context: https://gitlab.com/gitlab-org/gitlab/-/issues/247207
/* eslint-disable vue/no-v-html */
import { GlPopover } from '@gitlab/ui';
import { sanitize } from '~/lib/dompurify';

const newPopover = element => {
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
  data() {
    return {
      popovers: [],
    };
  },
  created() {
    this.observer = new MutationObserver(mutations => {
      mutations.forEach(mutation => {
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
        const index = this.popovers.findIndex(popover => popover.target === target);

        if (index > -1) {
          this.popovers.splice(index, 1);
        }
      }
    },
    popoverExists(element) {
      return this.popovers.some(popover => popover.target === element);
    },
    getSafeHtml(html) {
      return sanitize(html);
    },
  },
};
</script>

<template>
  <div>
    <gl-popover v-for="(popover, index) in popovers" :key="index" v-bind="popover">
      <template #title>
        <span v-if="popover.html" v-html="getSafeHtml(popover.title)"></span>
        <span v-else>{{ popover.title }}</span>
      </template>
      <span v-if="popover.html" v-html="getSafeHtml(popover.content)"></span>
      <span v-else>{{ popover.content }}</span>
    </gl-popover>
  </div>
</template>
