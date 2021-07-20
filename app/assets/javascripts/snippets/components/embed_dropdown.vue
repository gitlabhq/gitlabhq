<script>
import {
  GlButton,
  GlDropdown,
  GlDropdownSectionHeader,
  GlDropdownText,
  GlFormInputGroup,
  GlTooltipDirective,
} from '@gitlab/ui';
import { escape as esc } from 'lodash';
import { __ } from '~/locale';

const MSG_EMBED = __('Embed');
const MSG_SHARE = __('Share');
const MSG_COPY = __('Copy');

export default {
  components: {
    GlButton,
    GlDropdown,
    GlDropdownSectionHeader,
    GlDropdownText,
    GlFormInputGroup,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    url: {
      type: String,
      required: true,
    },
  },
  computed: {
    sections() {
      return [
        // eslint-disable-next-line no-useless-escape
        { name: MSG_EMBED, value: `<script src="${esc(this.url)}.js"><\/script>` },
        { name: MSG_SHARE, value: this.url },
      ];
    },
  },
  MSG_EMBED,
  MSG_COPY,
};
</script>
<template>
  <gl-dropdown
    right
    :text="$options.MSG_EMBED"
    menu-class="gl-px-1! gl-pb-5! gl-dropdown-menu-wide"
  >
    <template v-for="{ name, value } in sections">
      <gl-dropdown-section-header :key="`header_${name}`" data-testid="header">{{
        name
      }}</gl-dropdown-section-header>
      <gl-dropdown-text
        :key="`input_${name}`"
        tag="div"
        class="gl-dropdown-text-py-0 gl-dropdown-text-block"
        data-testid="input"
      >
        <gl-form-input-group :value="value" readonly select-on-click :label="name">
          <template #append>
            <gl-button
              v-gl-tooltip.hover
              :title="$options.MSG_COPY"
              :aria-label="$options.MSG_COPY"
              :data-clipboard-text="value"
              icon="copy-to-clipboard"
              data-qa-selector="copy_button"
              :data-qa-action="name"
            />
          </template>
        </gl-form-input-group>
      </gl-dropdown-text>
    </template>
  </gl-dropdown>
</template>
