<script>
  import icon from '~/vue_shared/components/icon.vue';

  export default {
    components: {
      icon,
    },
    props: {
      buttonTitle: {
        type: String,
        required: true,
      },
    },
    data() {
      return {
        toggleState: false,
      };
    },
    computed: {
      toggleButtonIcon() {
        return this.toggleState ? 'angle-up' : 'angle-down';
      },
    },
    methods: {
      onClickButton() {
        this.toggleState = !this.toggleState;
        this.$emit('toggleButton', this.toggleState);
      },
    },
  };
</script>

<template>
  <button
    class="btn-link btn-show-section"
    type="button"
    @click="onClickButton"
  >
    <icon
      :size="16"
      :name="toggleButtonIcon"
    />
    <span class="prepend-left-8">{{ buttonTitle }}</span>
  </button>
</template>
