<script>
import { GlButton, GlTooltipDirective } from '@gitlab/ui';
import { I18N_DELETE_RUNNER } from '../constants';
import RunnerDeleteAction from './runner_delete_action.vue';

export default {
  name: 'RunnerDeleteButton',
  components: {
    GlButton,
    RunnerDeleteAction,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    runner: {
      type: Object,
      required: true,
    },
    compact: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  emits: ['deleted'],
  data() {
    return {
      deleting: false,
    };
  },
  computed: {
    buttonContent() {
      if (this.compact) {
        return null;
      }
      return I18N_DELETE_RUNNER;
    },
    icon() {
      if (this.compact) {
        return 'close';
      }
      return '';
    },
    buttonClass() {
      // Ensure a square button is shown when compact: true.
      // Without this class we will have distorted/rectangular button.
      if (this.compact) {
        return 'btn-icon';
      }
      return null;
    },
    ariaLabel() {
      if (this.compact) {
        return I18N_DELETE_RUNNER;
      }
      return null;
    },
    tooltip() {
      if (this.compact) {
        return I18N_DELETE_RUNNER;
      }
      return '';
    },
  },
  methods: {
    onDone(event) {
      this.$emit('deleted', event);
    },
  },
};
</script>

<template>
  <runner-delete-action class="btn-group" :runner="runner" @done="onDone">
    <template #default="{ loading, onClick }">
      <gl-button
        v-gl-tooltip="loading ? '' : tooltip"
        :aria-label="ariaLabel"
        :icon="icon"
        :class="buttonClass"
        :loading="loading"
        variant="danger"
        category="secondary"
        v-bind="$attrs"
        @click="onClick"
      >
        {{ buttonContent }}
      </gl-button>
    </template>
  </runner-delete-action>
</template>
