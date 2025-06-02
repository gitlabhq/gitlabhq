<script>
import { GlButton, GlButtonGroup } from '@gitlab/ui';

export default {
  name: 'BooleanCell',
  components: {
    GlButton,
    GlButtonGroup,
  },
  props: {
    input: {
      type: Object,
      required: true,
    },
  },
  emits: ['update'],
  computed: {
    inputValue: {
      get() {
        return this.convertToDisplayValue(this.input.value);
      },
      set(newValue) {
        if (newValue === this.convertToDisplayValue(this.input.value)) return;

        const value = newValue === 'true';
        this.$emit('update', {
          input: this.input,
          value,
        });
      },
    },
  },
  methods: {
    convertToDisplayValue(value) {
      if (value === undefined || value === null) {
        return 'false';
      }
      return value.toString();
    },
    handleClick(option) {
      this.inputValue = option;
    },
  },
};
</script>

<template>
  <div>
    <gl-button-group :aria-label="input.name">
      <gl-button
        v-for="option in ['true', 'false']"
        :key="option"
        :selected="inputValue === option"
        :aria-checked="inputValue === option"
        variant="default"
        @click="handleClick(option)"
      >
        {{ option }}
      </gl-button>
    </gl-button-group>
  </div>
</template>
