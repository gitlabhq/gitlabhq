<script>
import { GlSprintf } from '@gitlab/ui';
import { s__ } from '~/locale';
import HelpPageLink from '~/vue_shared/components/help_page_link/help_page_link.vue';
import { PLACEHOLDERS } from '../constants';

export default {
  components: { GlSprintf, HelpPageLink },
  PLACEHOLDERS,
  i18n: {
    example: s__('Badges|Example: %{exampleUrl}'),
    supportedVariables: s__(
      'Badges|Supported %{docsLinkStart}placeholders%{docsLinkEnd}: %{placeholders}',
    ),
  },
  methods: {
    placeholderText(placeholder) {
      return `%{${placeholder}}`;
    },
  },
};
</script>

<template>
  <span class="gl-leading-24">
    <gl-sprintf :message="$options.i18n.supportedVariables">
      <template #docsLink="{ content }">
        <help-page-link href="user/project/badges" anchor="placeholders">{{
          content
        }}</help-page-link>
      </template>
      <template #placeholders>
        <template v-for="(placeholder, index) in $options.PLACEHOLDERS">
          <code :key="placeholder">{{ placeholderText(placeholder) }}</code
          ><template v-if="index + 1 < $options.PLACEHOLDERS.length">, </template>
        </template>
      </template>
    </gl-sprintf>
  </span>
</template>
