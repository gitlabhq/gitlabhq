<script>
  import { mapGetters, mapActions } from 'vuex';
  import Flash from '../../flash';
  import store from '../stores';
  import collapsibleContainer from './collapsible_container.vue';
  import { errorMessages, errorMessagesTypes } from '../constants';

  export default {
    name: 'RegistryListApp',
    components: {
      collapsibleContainer,
    },
    props: {
      endpoint: {
        type: String,
        required: true,
      },
    },
    store,
    computed: {
      ...mapGetters([
        'isLoading',
        'repos',
      ]),
    },
    created() {
      this.setMainEndpoint(this.endpoint);
    },
    mounted() {
      this.fetchRepos()
        .catch(() => Flash(errorMessages[errorMessagesTypes.FETCH_REPOS]));
    },
    methods: {
      ...mapActions([
        'setMainEndpoint',
        'fetchRepos',
      ]),
    },
  };
</script>
<template>
  <div>
    <gl-loading-icon
      v-if="isLoading"
      :size="3"
    />

    <collapsible-container
      v-for="(item, index) in repos"
      v-else-if="!isLoading && repos.length"
      :key="index"
      :repo="item"
    />

    <p v-else-if="!isLoading && !repos.length">
      {{ __(`No container images stored for this project.
Add one by following the instructions above.`) }}
    </p>
  </div>
</template>
