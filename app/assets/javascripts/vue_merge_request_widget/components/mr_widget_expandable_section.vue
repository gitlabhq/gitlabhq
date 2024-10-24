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
    <div class="mr-widget-body gl-flex">
      <span class="gl-mr-3 gl-mt-1 gl-flex gl-items-center gl-justify-center gl-self-start">
        <gl-icon :name="iconName" :size="24" />
      </span>

      <div class="gl-flex gl-grow gl-flex-col md:gl-flex-row">
        <slot name="header"></slot>

        <div>
          <gl-button @click="updateContentVisibility">
            {{ collapseButtonText }}
          </gl-button>
        </div>
      </div>
    </div>

    <gl-collapse :visible="contentIsVisible" class="gl-border-t gl-border-t-section gl-bg-subtle">
      <slot name="content"></slot>
    </gl-collapse>
  </div>
</template>
