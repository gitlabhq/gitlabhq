<script>
import { mapGetters, mapActions } from 'vuex';
import { GlLoadingIcon } from '@gitlab/ui';
import store from '../stores';
import CollapsibleContainer from './collapsible_container.vue';

export default {
  name: 'RegistryListApp',
  components: {
    CollapsibleContainer,
    GlLoadingIcon,
  },
  props: {
    endpoint: {
      type: String,
      required: true,
    },
  },
  store,
  computed: {
    ...mapGetters(['isLoading', 'repos']),
  },
  created() {
    this.setMainEndpoint(this.endpoint);
  },
  mounted() {
    this.fetchRepos();
  },
  methods: {
    ...mapActions(['setMainEndpoint', 'fetchRepos']),
  },
};
</script>
<template>
  <div>
    <gl-loading-icon v-if="isLoading" size="md" />

    <collapsible-container
      v-for="item in repos"
      v-else-if="!isLoading && repos.length"
      :key="item.id"
      :repo="item"
    />

    <p v-else-if="!isLoading && !repos.length">
      {{
        __(`No container images stored for this project.
      Add one by following the instructions above.`)
      }}
    </p>
  </div>
</template>
