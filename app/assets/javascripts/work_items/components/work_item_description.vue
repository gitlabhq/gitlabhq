<script>
import { GlSafeHtmlDirective } from '@gitlab/ui';
import Tracking from '~/tracking';

export default {
  directives: {
    SafeHtml: GlSafeHtmlDirective,
  },
  mixins: [Tracking.mixin()],
  props: {
    workItem: {
      type: Object,
      required: true,
    },
    workItemDescription: {
      type: Object,
      required: false,
      default: () => ({}),
    },
  },
  computed: {
    tracking() {
      return {
        category: 'workItems:show',
        label: 'item_description',
        property: `type_${this.workItem.workItemType.name}`,
      };
    },
    descriptionHtml() {
      return this.workItemDescription?.descriptionHtml;
    },
  },
};
</script>

<template>
  <div v-if="descriptionHtml" class="gl-pt-5 gl-mb-5 gl-border-t gl-border-b">
    <h3 class="gl-font-base gl-mt-0">{{ __('Description') }}</h3>
    <div v-safe-html="descriptionHtml" class="md gl-mb-5"></div>
  </div>
</template>
