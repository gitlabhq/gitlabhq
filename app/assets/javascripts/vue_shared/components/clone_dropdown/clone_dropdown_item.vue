<script>
import {
  GlButton,
  GlDisclosureDropdownItem,
  GlFormGroup,
  GlFormInputGroup,
  GlTooltipDirective,
} from '@gitlab/ui';
import { __ } from '~/locale';

export default {
  components: {
    GlDisclosureDropdownItem,
    GlFormGroup,
    GlFormInputGroup,
    GlButton,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    label: {
      type: String,
      required: true,
    },
    link: {
      type: String,
      required: true,
    },
    qaSelector: {
      type: String,
      required: true,
    },
  },
  copyURLTooltip: __('Copy URL'),
};
</script>
<template>
  <gl-disclosure-dropdown-item>
    <gl-form-group :label="label" class="gl-px-3 gl-mb-3">
      <gl-form-input-group :value="link" readonly select-on-click>
        <template #append>
          <gl-button
            v-gl-tooltip.hover
            :title="$options.copyURLTooltip"
            :aria-label="$options.copyURLTooltip"
            :data-clipboard-text="link"
            :data-qa-selector="qaSelector"
            icon="copy-to-clipboard"
            class="gl-display-inline-flex"
          />
        </template>
      </gl-form-input-group>
    </gl-form-group>
  </gl-disclosure-dropdown-item>
</template>
