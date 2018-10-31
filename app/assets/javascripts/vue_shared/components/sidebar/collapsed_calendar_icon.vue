<script>
import tooltip from '~/vue_shared/directives/tooltip';

export default {
  name: 'CollapsedCalendarIcon',
  directives: {
    tooltip,
  },
  props: {
    containerClass: {
      type: String,
      required: false,
      default: '',
    },
    text: {
      type: String,
      required: false,
      default: '',
    },
    showIcon: {
      type: Boolean,
      required: false,
      default: true,
    },
    tooltipText: {
      type: String,
      required: false,
      default: '',
    },
  },
  methods: {
    click() {
      this.$emit('click');
    },
  },
};
</script>

<template>
  <div
    v-tooltip
    :class="containerClass"
    :title="tooltipText"
    data-container="body"
    data-placement="left"
    data-html="true"
    data-boundary="viewport"
    @click="click"
  >
    <i
      v-if="showIcon"
      class="fa fa-calendar"
      aria-hidden="true"
    >
    </i>
    <slot>
      <span>
        {{ text }}
      </span>
    </slot>
  </div>
</template>
