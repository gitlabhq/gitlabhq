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
    :class="containerClass"
    @click="click"
    v-tooltip
    data-container="body"
    data-placement="left"
    data-html="1"
    :title="tooltipText"
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
