<script>
import {
  GlButton,
  GlLoadingIcon,
  GlOutsideDirective as Outside,
  GlTooltipDirective,
} from '@gitlab/ui';
import { Mousetrap } from '~/lib/mousetrap';
import { keysFor, SIDEBAR_CLOSE_WIDGET } from '~/behaviors/shortcuts/keybindings';

export default {
  name: 'WorkItemSidebarWidget',
  components: {
    GlButton,
    GlLoadingIcon,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
    Outside,
  },
  props: {
    canUpdate: {
      type: Boolean,
      required: false,
      default: false,
    },
    // Declared as a prop so it stays out of $attrs. BootstrapVue copies the host
    // component's $attrs onto the tooltip element it appends to the page body,
    // which would otherwise duplicate this test ID outside the widget.
    dataTestid: {
      type: String,
      required: false,
      default: null,
    },
    isEditing: {
      type: Boolean,
      required: false,
      default: false,
    },
    isUpdating: {
      type: Boolean,
      required: false,
      default: false,
    },
    tooltipText: {
      type: String,
      required: false,
      default: undefined,
    },
  },
  emits: ['start-editing', 'stop-editing'],
  data() {
    return {
      editing: false,
    };
  },
  watch: {
    isEditing(isEditing) {
      this.editing = isEditing;
    },
  },
  mounted() {
    Mousetrap.bind(keysFor(SIDEBAR_CLOSE_WIDGET), this.stopEditing);
  },
  beforeDestroy() {
    Mousetrap.unbind(keysFor(SIDEBAR_CLOSE_WIDGET));
  },
  methods: {
    startEditing() {
      this.editing = true;
      this.$emit('start-editing');
    },
    stopEditing({ target } = {}) {
      // This prevents the v-outside directive from treating a
      // click on the datepicker dropdown as an outside click
      if (target?.classList.contains('pika-select')) {
        return;
      }
      this.editing = false;
      this.$emit('stop-editing');
    },
  },
};
</script>

<template>
  <section :data-testid="dataTestid">
    <div class="gl-flex gl-items-center gl-gap-3">
      <h3 class="gl-heading-5 gl-mb-0">
        <slot name="title"></slot>
      </h3>
      <gl-loading-icon v-if="isUpdating" />
      <gl-button
        v-if="canUpdate && !editing"
        key="edit-button"
        v-gl-tooltip.viewport.html
        class="shortcut-sidebar-dropdown-toggle gl-ml-auto gl-shrink-0"
        category="tertiary"
        :disabled="isUpdating"
        size="small"
        :title="tooltipText"
        data-testid="edit-button"
        @click="startEditing"
      >
        {{ __('Edit') }}
      </gl-button>
      <gl-button
        v-if="editing"
        key="apply-button"
        class="gl-ml-auto gl-shrink-0"
        category="tertiary"
        :disabled="isUpdating"
        size="small"
        data-testid="apply-button"
        @click="stopEditing"
      >
        {{ __('Apply') }}
      </gl-button>
    </div>
    <div v-if="editing" v-outside="stopEditing">
      <slot name="editing-content" :stop-editing="stopEditing"></slot>
    </div>
    <slot v-else name="content"></slot>
  </section>
</template>
