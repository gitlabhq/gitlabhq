<script>
import { GlFormInputGroup, GlButton, GlIcon } from '@gitlab/ui';
import { __ } from '~/locale';

export default {
  components: {
    GlFormInputGroup,
    GlButton,
    GlIcon,
  },
  props: {
    url: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      optionValues: [
        // eslint-disable-next-line no-useless-escape
        { name: __('Embed'), value: `<script src='${this.url}.js'><\/script>` },
        { name: __('Share'), value: this.url },
      ],
    };
  },
};
</script>
<template>
  <gl-form-input-group
    id="embeddable-text"
    :predefined-options="optionValues"
    readonly
    select-on-click
  >
    <template #append>
      <gl-button new-style data-clipboard-target="#embeddable-text">
        <gl-icon name="copy-to-clipboard" :title="__('Copy')" />
      </gl-button>
    </template>
  </gl-form-input-group>
</template>
