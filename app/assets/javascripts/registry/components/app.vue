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
      ]),
    },
    created() {
      this.setMainEndpoint(this.endpoint);
    },
    mounted() {
      this.fetchRepos()
        .catch(() => Flash(errorMessages[errorMessagesTypes.FETCH_REPOS]));
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
      />

    <p v-else-if="!isLoading && !repos.length">
      {{__("No container images stored for this project. Add one by following the instructions above.")}}
    </p>
  </div>
</template>
