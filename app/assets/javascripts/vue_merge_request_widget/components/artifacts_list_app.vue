<script>
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
  <mr-collapsible-extension :title="title" :is-loading="isLoading" :has-error="hasError">
    <artifacts-list :artifacts="artifacts" />
  </mr-collapsible-extension>
</template>
