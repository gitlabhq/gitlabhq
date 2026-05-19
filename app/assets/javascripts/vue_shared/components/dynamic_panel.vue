<script>
import PanelActions from './panel_actions.vue';

export default {
  name: 'DynamicPanel',
  components: {
    PanelActions,
  },
  provide() {
    return { panelHeadingTag: 'h2' };
  },
  props: {
    /**
     * Text to display in the panel header. The header slot takes precedence.
     */
    header: {
      type: String,
      required: false,
      default: null,
    },
    /**
     * URL for the maximized panel. When set to a truthy value, the maximize button is rendered.
     */
    maximizeUrl: {
      type: String,
      required: false,
      default: null,
    },
  },
  emits: ['close', 'maximize'],
};
</script>

<template>
  <div class="paneled-view js-paneled-view contextual-panel !gl-w-full">
    <div class="panel-header">
      <div class="panel-header-inner">
        <slot name="header">
          <span class="panel-header-inner-text">{{ header }}</span>
        </slot>

        <panel-actions
          :maximize-url="maximizeUrl"
          @close="$emit('close')"
          @maximize="$emit('maximize', $event)"
        >
          <slot name="actions"></slot>
        </panel-actions>
      </div>
    </div>
    <div class="panel-content">
      <div class="panel-content-inner js-dynamic-panel-inner">
        <div class="container-fluid">
          <div class="content gl-pb-3 gl-@container/panel">
            <slot></slot>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
