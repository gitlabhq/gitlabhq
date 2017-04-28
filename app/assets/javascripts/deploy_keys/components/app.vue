<script>
  /* global Flash */
  import eventHub from '../eventhub';
  import DeployKeysService from '../service';
  import DeployKeysStore from '../store';
  import keysPanel from './keys_panel.vue';

  export default {
    data() {
      return {
        isLoading: false,
        store: new DeployKeysStore(),
      };
    },
    props: {
      endpoint: {
        type: String,
        required: true,
      },
    },
    computed: {
      hasKeys() {
        return Object.keys(this.keys).length;
      },
      keys() {
        return this.store.keys;
      },
    },
    components: {
      keysPanel,
    },
    methods: {
      fetchKeys() {
        this.isLoading = true;
        this.store.keys = {};

        this.service.getKeys()
          .then((data) => {
            this.isLoading = false;
            this.store.keys = data;
          })
          .catch(() => new Flash('Error getting deploy keys'));
      },
      enableKey(deployKey) {
        this.service.enableKey(deployKey.id)
          .then(() => this.fetchKeys())
          .catch(() => new Flash('Error enabling deploy key'));
      },
      removeKey(deployKey) {
        this.disableKey(deployKey);
      },
      disableKey(deployKey) {
        // eslint-disable-next-line no-alert
        if (confirm('You are going to remove this deploy key. Are you sure?')) {
          this.service.disableKey(deployKey.id)
            .then(() => this.fetchKeys())
            .catch(() => new Flash('Error removing deploy key'));
        }
      },
    },
    created() {
      this.service = new DeployKeysService(this.endpoint);

      eventHub.$on('enable.key', this.enableKey);
      eventHub.$on('remove.key', this.removeKey);
      eventHub.$on('disable.key', this.disableKey);
    },
    mounted() {
      this.fetchKeys();
    },
    beforeDestroy() {
      eventHub.$off('enable.key', this.enableKey);
      eventHub.$off('remove.key', this.removeKey);
      eventHub.$off('disable.key', this.disableKey);
    },
  };
</script>

<template>
  <div class="col-lg-9 col-lg-offset-3 append-bottom-default deploy-keys">
    <div
      class="text-center"
      v-if="isLoading && !hasKeys">
      <i
        class="fa fa-spinner fa-spin fa-2x"
        aria-hidden="true"
        aria-label="Loading deploy keys">
      </i>
    </div>
    <div v-else-if="hasKeys">
      <keys-panel
        title="Enabled deploy keys for this project"
        :keys="keys.enabled_keys"
        :store="store" />
      <keys-panel
        title="Deploy keys from projects you have access to"
        :keys="keys.available_project_keys"
        :store="store" />
      <keys-panel
        v-if="keys.public_keys.length"
        title="Public deploy keys available to any project"
        :keys="keys.public_keys"
        :store="store" />
    </div>
  </div>
</template>
