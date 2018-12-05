<script>
import { mapGetters, mapActions } from 'vuex';
import { GlLoadingIcon } from '@gitlab/ui';
import createFlash from '../../flash';
import store from '../stores';
import collapsibleContainer from './collapsible_container.vue';
import { errorMessages, errorMessagesTypes } from '../constants';

export default {
  name: 'RegistryListApp',
  components: {
    collapsibleContainer,
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
    <gl-loading-icon v-if="isLoading" :size="3" />

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
