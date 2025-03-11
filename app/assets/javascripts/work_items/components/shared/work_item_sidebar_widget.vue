<script>
import { GlButton, GlOutsideDirective as Outside } from '@gitlab/ui';
import { Mousetrap } from '~/lib/mousetrap';
import { keysFor, SIDEBAR_CLOSE_WIDGET } from '~/behaviors/shortcuts/keybindings';

export default {
  components: {
    GlButton,
  },
  directives: {
    Outside,
  },
  props: {
    canUpdate: {
      type: Boolean,
      required: false,
      default: false,
    },
    isUpdating: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      isEditing: false,
    };
  },
  mounted() {
    Mousetrap.bind(keysFor(SIDEBAR_CLOSE_WIDGET), this.stopEditing);
  },
  beforeDestroy() {
    Mousetrap.unbind(keysFor(SIDEBAR_CLOSE_WIDGET));
  },
  methods: {
    startEditing() {
      this.isEditing = true;
    },
    stopEditing({ target } = {}) {
      // This prevents the v-outside directive from treating a
      // click on the datepicker dropdown as an outside click
      if (target?.classList.contains('pika-select')) {
        return;
      }
      this.isEditing = false;
      this.$emit('stopEditing');
    },
  },
};
</script>

<template>
  <section>
    <div class="gl-flex gl-items-center gl-gap-3">
      <h3 class="gl-heading-5 gl-mb-0">
        <slot name="title"></slot>
      </h3>
      <gl-button
        v-if="canUpdate && !isEditing"
        key="edit-button"
        class="gl-ml-auto gl-shrink-0"
        category="tertiary"
        :disabled="isUpdating"
        size="small"
        data-testid="edit-button"
        @click="startEditing"
      >
        {{ __('Edit') }}
      </gl-button>
      <gl-button
        v-if="isEditing"
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
    <div v-if="isEditing" v-outside="stopEditing">
      <slot name="editing-content" :stop-editing="stopEditing"></slot>
    </div>
    <slot v-else name="content"></slot>
  </section>
</template>
