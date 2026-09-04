<script>
import { glSlotsMixin } from '~/lib/utils/vue3compat/gl_slots_mixin';
import PanelActions from './panel_actions.vue';

export default {
  name: 'DynamicPanel',
  components: {
    PanelActions,
  },
  mixins: [glSlotsMixin],
  provide() {
    return {
      panelHeadingTag: 'h2',
      fluidLayout: this.fluidLayout,
    };
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
    /**
     * Force fluid layout.
     */
    fluidLayout: {
      type: Boolean,
      required: false,
      default: () => window.gon?.fluid_layout ?? false,
    },
    shouldFillContent: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  emits: ['close', 'maximize'],
  computed: {
    fillContentClasses() {
      return this.shouldFillContent ? 'gl-flex gl-flex-col gl-flex-1 gl-min-h-0' : null;
    },
  },
  mounted() {
    this.$nextTick(this.syncPanelContentHeight);
    window.addEventListener('resize', this.syncPanelContentHeight);
  },
  beforeDestroy() {
    window.removeEventListener('resize', this.syncPanelContentHeight);
  },
  methods: {
    syncPanelContentHeight() {
      const el = this.$refs.panelContentInner;
      if (!el) return;
      // Scope the height to this panel so nested sticky elements (like the
      // detail-layout sidebar) size to the panel they live in, not whichever
      // .panel-content-inner the global panel_height_calc measured first.
      el.style.setProperty(
        '--panel-content-inner-height',
        `${el.getBoundingClientRect().height}px`,
      );
    },
  },
};
</script>

<template>
  <div class="paneled-view js-paneled-view contextual-panel !gl-h-full !gl-w-full">
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
          <template v-if="glSlots().actions" #default><slot name="actions"></slot></template>
        </panel-actions>
      </div>
    </div>
    <div class="panel-content">
      <div
        ref="panelContentInner"
        class="panel-content-inner js-dynamic-panel-inner"
        :class="fillContentClasses"
        data-testid="panel-content-inner"
      >
        <div
          class="container-fluid"
          :class="[{ 'container-limited': !fluidLayout }, fillContentClasses]"
          data-testid="layout-container"
        >
          <div
            class="content gl-@container/panel"
            :class="fillContentClasses"
            data-testid="panel-content"
          >
            <slot></slot>
          </div>
        </div>
      </div>

      <div v-if="glSlots().footer" class="panel-footer" data-testid="panel-footer">
        <slot name="footer"></slot>
      </div>
    </div>
  </div>
</template>
