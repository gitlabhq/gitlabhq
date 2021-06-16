<script>
import { GlButton, GlCollapse, GlIcon } from '@gitlab/ui';
import { __ } from '~/locale';

/**
 * Renders header section with icon and expand button
 * Renders expanable content section with grey background
 */
export default {
  name: 'MrWidgetExpanableSection',
  components: {
    GlButton,
    GlCollapse,
    GlIcon,
  },
  props: {
    iconName: {
      type: String,
      required: false,
      default: 'status_warning',
    },
  },
  data() {
    return {
      contentIsVisible: false,
    };
  },
  computed: {
    collapseButtonText() {
      if (this.contentIsVisible) {
        return __('Collapse');
      }

      return __('Expand');
    },
  },
  methods: {
    updateContentVisibility() {
      this.contentIsVisible = !this.contentIsVisible;
    },
  },
};
</script>

<template>
  <div>
    <div class="mr-widget-body gl-display-flex">
      <span
        class="gl-display-flex gl-align-items-center gl-justify-content-center gl-mr-3 gl-align-self-start gl-mt-1"
      >
        <gl-icon :name="iconName" :size="24" />
      </span>

      <div class="gl-display-flex gl-flex-grow-1 gl-flex-direction-column gl-md-flex-direction-row">
        <slot name="header"></slot>

        <div>
          <gl-button @click="updateContentVisibility">
            {{ collapseButtonText }}
          </gl-button>
        </div>
      </div>
    </div>

    <gl-collapse
      :visible="contentIsVisible"
      class="gl-bg-gray-10 gl-border-t-solid gl-border-gray-100 gl-border-1"
    >
      <slot name="content"></slot>
    </gl-collapse>
  </div>
</template>
