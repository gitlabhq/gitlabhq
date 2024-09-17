<script>
// eslint-disable-next-line no-restricted-syntax
import { GlSafeHtmlDirective as SafeHtml, GlSprintf } from '@gitlab/ui';
import { random } from 'lodash';
import { s__ } from '~/locale';

export default {
  name: 'CommandPaletteLottery',
  components: {
    GlSprintf,
  },
  directives: {
    SafeHtml,
  },
  i18n: [
    s__('GlobalSearch|Type %{linkStart}@%{linkEnd} to search for users'),
    s__('GlobalSearch|Type %{linkStart}&gt;%{linkEnd} to search for pages or actions'),
    s__('GlobalSearch|Type %{linkStart}:%{linkEnd} to search for projects'),
    s__('GlobalSearch|Type %{linkStart}t%{linkEnd} to search for files'),
  ],
  computed: {
    getTipNum() {
      const max = this.$options.i18n.length - 1;
      return random(0, max);
    },
  },
};
</script>

<template>
  <span>
    <gl-sprintf :message="$options.i18n[getTipNum]">
      <template #link="{ content }">
        <kbd v-safe-html="content" class="vertical-align-normalization gl-py-2 gl-text-base">{{
          content
        }}</kbd>
      </template>
    </gl-sprintf>
  </span>
</template>
