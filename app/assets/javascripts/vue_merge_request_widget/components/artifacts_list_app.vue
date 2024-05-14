<script>
// eslint-disable-next-line no-restricted-imports
import { mapActions, mapState, mapGetters } from 'vuex';
import createStore from '../stores/artifacts_list';
import ArtifactsList from './artifacts_list.vue';
import MrCollapsibleExtension from './mr_collapsible_extension.vue';

export default {
  store: createStore(),
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
    ...mapState(['artifacts', 'isLoading', 'hasError']),
    ...mapGetters(['title']),
    hasArtifacts() {
      return this.artifacts.length > 0;
    },
  },
  created() {
    this.setEndpoint(this.endpoint);
    this.fetchArtifacts();
  },
  methods: {
    ...mapActions(['setEndpoint', 'fetchArtifacts']),
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
