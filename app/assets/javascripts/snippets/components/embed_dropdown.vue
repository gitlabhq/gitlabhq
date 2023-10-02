<script>
import { GlButton, GlDisclosureDropdown, GlFormInputGroup, GlTooltipDirective } from '@gitlab/ui';
import { escape as esc } from 'lodash';
import { __ } from '~/locale';

const MSG_EMBED = __('Embed');
const MSG_SHARE = __('Share');
const MSG_COPY = __('Copy');

export default {
  components: {
    GlButton,
    GlDisclosureDropdown,
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
  <gl-disclosure-dropdown
    :auto-close="false"
    fluid-width
    placement="right"
    :toggle-text="$options.MSG_EMBED"
  >
    <template v-for="{ name, value } in sections">
      <div :key="name" :data-testid="`section-${name}`" class="gl-px-4 gl-py-2">
        <h5 class="gl-font-sm gl-mt-1 gl-mb-2" data-testid="header">{{ name }}</h5>
        <gl-form-input-group class="gl-w-31" :value="value" readonly select-on-click :label="name">
          <template #append>
            <gl-button
              v-gl-tooltip.hover
              :title="$options.MSG_COPY"
              :aria-label="$options.MSG_COPY"
              :data-clipboard-text="value"
              icon="copy-to-clipboard"
              data-testid="copy-button"
              :data-qa-action="name"
            />
          </template>
        </gl-form-input-group>
      </div>
    </template>
  </gl-disclosure-dropdown>
</template>
