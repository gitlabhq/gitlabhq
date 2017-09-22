<script>
  /* globals Flash */
  import { mapGetters, mapActions } from 'vuex';
  import '../../flash';
  import loadingIcon from '../../vue_shared/components/loading_icon.vue';
  import store from '../stores';
  import collapsibleContainer from './collapsible_container.vue';
  import { errorMessages, errorMessagesTypes } from '../constants';

  export default {
    name: 'registryListApp',
    props: {
      endpoint: {
        type: String,
        required: true,
      },
    },
    store,
    components: {
      collapsibleContainer,
      loadingIcon,
    },
    computed: {
      ...mapGetters([
        'isLoading',
        'repos',
      ]),
    },
    methods: {
      ...mapActions([
        'setMainEndpoint',
        'fetchRepos',
        'fetchList',
        'deleteRepo',
        'deleteRegistry',
        'toggleLoading',
      ]),

      fetchRegistryList(repo) {
        this.fetchList({ repo })
          .catch(() => this.showError(errorMessagesTypes.FETCH_REGISTRY));
      },

      deleteRegistry(repo, registry) {
        this.deleteRegistry(registry)
          .then(() => this.fetchRegistry(repo))
          .catch(() => this.showError(errorMessagesTypes.DELETE_REGISTRY));
      },

      deleteRepository(repo) {
        this.deleteRepo(repo)
          .then(() => this.fetchRepos())
          .catch(() => this.showError(errorMessagesTypes.DELETE_REPO));
      },

      showError(message) {
        Flash(this.__(errorMessages[message]));
      },

      onPageChange(repo, page) {
        this.fetchList({ repo, page })
          .catch(() => this.showError(errorMessagesTypes.FETCH_REGISTRY));
      },
    },
    created() {
      this.setMainEndpoint(this.endpoint);
    },
    mounted() {
      this.fetchRepos()
        .catch(() => this.showError(errorMessagesTypes.FETCH_REPOS));
    },
  };
</script>
<template>
  <div>
    <loading-icon
      v-if="isLoading"
      size="3"
      />

    <collapsible-container
      v-else-if="!isLoading && repos.length"
      v-for="(item, index) in repos"
      :key="index"
      :repo="item"
      @fetchRegistryList="fetchRegistryList"
      @deleteRepository="deleteRepository"
      @deleteRegistry="deleteRegistry"
      @pageChange="onPageChange"
      />

    <p v-else-if="!isLoading && !repos.length">
      {{__("No container images stored for this project. Add one by following the instructions above.")}}
    </p>
  </div>
</template>
