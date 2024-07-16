<script>
import { GlButton, GlDisclosureDropdown } from '@gitlab/ui';
import { joinPaths } from '~/lib/utils/url_utility';
import { s__ } from '~/locale';

export default {
  components: {
    GlButton,
    GlDisclosureDropdown,
  },
  props: {
    containers: {
      type: Array,
      required: true,
      validator: (fields) => fields.length && fields.every(({ name }) => typeof name === 'string'),
    },
    namespace: {
      type: String,
      required: true,
    },
    podName: {
      type: String,
      required: true,
    },
  },
  computed: {
    hasMultipleContainers() {
      return this.containers.length > 1;
    },
    containersList() {
      return this.containers.map(({ name }) => {
        return { text: name, to: this.getLogsLink(name) };
      });
    },
  },
  methods: {
    getLogsLink(name = '') {
      let link = joinPaths(
        gon.relative_url_root || '',
        `/k8s/namespace/${this.namespace}/pods/${this.podName}/logs`,
      );

      const containerName = name || this.containers[0].name;
      if (containerName) {
        link += `?container=${containerName}`;
      }

      return link;
    },
  },
  i18n: {
    buttonText: s__('Environments|View logs'),
  },
};
</script>
<template>
  <gl-disclosure-dropdown
    v-if="hasMultipleContainers"
    :toggle-text="$options.i18n.buttonText"
    :items="containersList"
    size="small"
  />

  <gl-button v-else :to="getLogsLink()" size="small">{{ $options.i18n.buttonText }}</gl-button>
</template>
