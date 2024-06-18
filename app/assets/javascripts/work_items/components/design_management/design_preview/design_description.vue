<script>
import { s__ } from '~/locale';
import SafeHtml from '~/vue_shared/directives/safe_html';

export default {
  i18n: {
    descriptionLabel: s__('DesignManagement|Description'),
  },
  directives: {
    SafeHtml,
  },
  props: {
    design: {
      type: Object,
      required: true,
    },
  },
};
</script>

<template>
  <div class="design-description-container">
    <div class="design-description-view">
      <div class="design-description-header gl-flex gl-justify-between gl-mb-2">
        <h3 class="!gl-leading-20 gl-font-lg gl-m-0">
          {{ $options.i18n.descriptionLabel }}
        </h3>
      </div>
      <div v-if="design.descriptionHtml" class="design-description js-task-list-container">
        <div
          ref="gfm-content"
          v-safe-html="design.descriptionHtml"
          class="md gl-mb-4"
          data-testid="design-description-content"
        ></div>
      </div>
    </div>
  </div>
</template>
