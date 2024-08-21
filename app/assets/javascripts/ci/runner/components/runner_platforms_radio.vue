<script>
import { GlFormRadio } from '@gitlab/ui';

export default {
  components: {
    GlFormRadio,
  },
  model: {
    event: 'input',
    prop: 'checked',
  },
  props: {
    image: {
      type: String,
      required: false,
      default: null,
    },
    checked: {
      type: String,
      required: false,
      default: null,
    },
    value: {
      type: String,
      required: false,
      default: null,
    },
  },
  computed: {
    isChecked() {
      return this.value && this.value === this.checked;
    },
    imgClass() {
      return 'gl-h-6 -gl-mt-2 gl-mr-2';
    },
  },
  methods: {
    onInput($event) {
      if (!$event) {
        return;
      }
      this.$emit('input', $event);
    },
    onChange($event) {
      this.$emit('change', $event);
    },
  },
};
</script>

<template>
  <div
    class="runner-platforms-radio gl-border gl-rounded-base gl-px-5 gl-pb-5 gl-pt-6"
    :class="{ 'gl-border-blue-500 gl-bg-blue-50': isChecked, 'gl-cursor-pointer': value }"
    @click="onInput(value)"
  >
    <gl-form-radio
      v-if="value"
      :checked="checked"
      :value="value"
      @input="onInput($event)"
      @change="onChange($event)"
    >
      <img v-if="image" :src="image" :class="imgClass" aria-hidden="true" />
      <span class="gl-font-bold"><slot></slot></span>
    </gl-form-radio>
    <div v-else class="gl-mb-3">
      <img v-if="image" :src="image" :class="imgClass" aria-hidden="true" />
      <span class="gl-font-bold"><slot></slot></span>
    </div>
  </div>
</template>

<style>
.runner-platforms-radio {
  min-width: 173px;
}
</style>
