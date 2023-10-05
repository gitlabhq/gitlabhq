<script>
import { GlButtonGroup, GlButton } from '@gitlab/ui';

const validateOptionsProp = (options) => {
  const requiredOptionPropType = {
    value: ['string', 'number', 'boolean'],
    disabled: ['boolean', 'undefined'],
  };
  const optionProps = Object.keys(requiredOptionPropType);

  return options.every((option) => {
    if (!option) {
      return false;
    }
    return optionProps.every((name) => requiredOptionPropType[name].includes(typeof option[name]));
  });
};

// TODO: We're planning to move this component to GitLab UI
//       https://gitlab.com/gitlab-org/gitlab-ui/-/issues/1787
export default {
  components: {
    GlButtonGroup,
    GlButton,
  },
  props: {
    options: {
      type: Array,
      required: true,
      validator: validateOptionsProp,
    },
    value: {
      type: [String, Number, Boolean],
      required: true,
    },
  },
};
</script>
<template>
  <gl-button-group>
    <gl-button
      v-for="opt in options"
      :key="opt.value"
      :disabled="!!opt.disabled"
      :selected="value === opt.value"
      @click="$emit('input', opt.value)"
    >
      <slot name="button-content" v-bind="opt">{{ opt.text }}</slot>
    </gl-button>
  </gl-button-group>
</template>
