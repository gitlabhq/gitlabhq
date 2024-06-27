<script>
import { GlDisclosureDropdown } from '@gitlab/ui';
import { s__, sprintf } from '~/locale';

export default {
  name: 'SecurityReportDownloadDropdown',
  components: {
    GlDisclosureDropdown,
  },
  props: {
    artifacts: {
      type: Array,
      required: true,
    },
    loading: {
      type: Boolean,
      required: false,
      default: false,
    },
    text: {
      type: String,
      required: false,
      default: '',
    },
  },
  computed: {
    showDropdown() {
      return this.loading || this.artifacts.length > 0;
    },
    items() {
      return this.artifacts.map(({ name, path }) => ({
        text: this.artifactText(name),
        href: path,
        extraAttrs: {
          download: '',
        },
      }));
    },
  },
  methods: {
    artifactText(name) {
      return sprintf(s__('SecurityReports|Download %{artifactName}'), {
        artifactName: name,
      });
    },
  },
};
</script>

<template>
  <gl-disclosure-dropdown
    v-if="showDropdown"
    :items="items"
    :toggle-text="text"
    :loading="loading"
    icon="download"
    size="small"
    placement="bottom-end"
  />
</template>
