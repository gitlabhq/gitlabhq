<script>
import { GlButton } from '@gitlab/ui';

import { s__ } from '~/locale';

import WidgetWrapper from '../widget_wrapper.vue';

export default {
  components: {
    WidgetWrapper,
    GlButton,
  },
  props: {
    workItemIid: {
      type: String,
      required: true,
    },
    workItemFullpath: {
      type: String,
      required: true,
    },
  },
  i18n: {
    title: s__('WorkItem|Linked Items'),
    emptyStateMessage: s__(
      "WorkItem|Link work items together to show that they're related or that one is blocking others.",
    ),
    addLinkedWorkItemButtonLabel: s__('WorkItem|Add'),
  },
};
</script>
<template>
  <widget-wrapper class="work-item-relationships">
    <template #header>{{ $options.i18n.title }}</template>
    <template #header-right>
      <gl-button size="small" class="gl-ml-3">
        <slot name="add-button-text">{{ $options.i18n.addLinkedWorkItemButtonLabel }}</slot>
      </gl-button>
    </template>
    <template #body>
      <div class="gl-new-card-content">
        <div data-testid="links-empty">
          <p class="gl-new-card-empty">
            {{ $options.i18n.emptyStateMessage }}
          </p>
        </div>
      </div>
    </template>
  </widget-wrapper>
</template>
