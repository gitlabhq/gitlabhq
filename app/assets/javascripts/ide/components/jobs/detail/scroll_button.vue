<script>
import { __ } from '../../../../locale';
import Icon from '../../../../vue_shared/components/icon.vue';
import tooltip from '../../../../vue_shared/directives/tooltip';

export default {
  directives: {
    tooltip,
  },
  components: {
    Icon,
  },
  props: {
    direction: {
      type: String,
      required: true,
      validator(value) {
        return ['up', 'down'].includes(value);
      },
    },
    disabled: {
      type: Boolean,
      required: true,
    },
  },
  computed: {
    tooltipTitle() {
      return this.direction === 'up' ? __('Scroll to top') : __('Scroll to bottom');
    },
    iconName() {
      return `scroll_${this.direction}`;
    },
  },
  methods: {
    clickedScroll() {
      this.$emit('click');
    },
  },
};
</script>

<template>
  <div
    v-tooltip
    class="controllers-buttons"
    data-container="body"
    data-placement="top"
    :title="tooltipTitle"
  >
    <button
      class="btn-scroll btn-transparent btn-blank"
      type="button"
      :disabled="disabled"
      @click="clickedScroll"
    >
      <icon
        :name="iconName"
      />
    </button>
  </div>
</template>
