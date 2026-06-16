<script>
import { mapActions, mapState } from 'pinia';
import { useArtifactsList } from '../stores/artifacts_list';
import ArtifactsList from './artifacts_list.vue';
import MrCollapsibleExtension from './mr_collapsible_extension.vue';

export default {
  name: 'ArtifactsListApp',
  components: {
    ArtifactsList,
    MrCollapsibleExtension,
  },
  props: {
    endpoint: {
      type: String,
      required: true,
    },
  },
  computed: {
    ...mapState(useArtifactsList, ['artifacts', 'isLoading', 'hasError', 'title']),
    hasArtifacts() {
      return this.artifacts.length > 0;
    },
  },
  created() {
    this.setEndpoint(this.endpoint);
    this.fetchArtifacts();
  },
  methods: {
    ...mapActions(useArtifactsList, ['setEndpoint', 'fetchArtifacts']),
  },
};
</script>
<template>
  <mr-collapsible-extension
    v-if="isLoading || hasArtifacts || hasError"
    :title="title"
    :is-loading="isLoading"
    :has-error="hasError"
  >
    <artifacts-list :artifacts="artifacts" />
  </mr-collapsible-extension>
</template>
