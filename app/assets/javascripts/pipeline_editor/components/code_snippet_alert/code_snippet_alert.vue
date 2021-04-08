<script>
import { GlAlert } from '@gitlab/ui';
import { CODE_SNIPPET_SOURCES, CODE_SNIPPET_SOURCE_SETTINGS } from './constants';

export default {
  name: 'CodeSnippetAlert',
  components: {
    GlAlert,
  },
  inject: ['configurationPaths'],
  props: {
    source: {
      type: String,
      required: true,
      validator: (source) => CODE_SNIPPET_SOURCES.includes(source),
    },
  },
  computed: {
    settings() {
      return CODE_SNIPPET_SOURCE_SETTINGS[this.source];
    },
    configurationPath() {
      return this.configurationPaths[this.source];
    },
  },
};
</script>

<template>
  <gl-alert
    variant="tip"
    :title="__('Code snippet copied. Insert it in the correct location in the YAML file.')"
    :dismiss-label="__('Dismiss')"
    :primary-button-link="settings.docsPath"
    :primary-button-text="__('Read documentation')"
    :secondary-button-link="configurationPath"
    :secondary-button-text="__('Go back to configuration')"
    v-on="$listeners"
  >
    {{ __('Before inserting code, be sure to read the comment that separated each code group.') }}
  </gl-alert>
</template>
