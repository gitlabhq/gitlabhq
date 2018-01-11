<script>
  export default {
    name: 'CollapsedCalendarIcon',
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
