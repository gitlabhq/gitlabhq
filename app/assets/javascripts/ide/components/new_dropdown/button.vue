<script>
import Icon from '~/vue_shared/components/icon.vue';

export default {
  components: {
    Icon,
  },
  props: {
    label: {
      type: String,
      required: false,
      default: null,
    },
    icon: {
      type: String,
      required: true,
    },
    iconClasses: {
      type: String,
      required: false,
      default: null,
    },
    showLabel: {
      type: Boolean,
      required: false,
      default: true,
    },
  },
  methods: {
    clicked() {
      this.$emit('click');
    },
  },
};
</script>

<template>
  <button
    :aria-label="label"
    type="button"
    class="btn-blank"
    @click.stop.prevent="clicked"
  >
    <icon
      :name="icon"
      :css-classes="iconClasses"
    />
    <template v-if="showLabel">
      {{ label }}
    </template>
  </button>
</template>
