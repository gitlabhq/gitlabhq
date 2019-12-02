<script>
import { s__ } from '~/locale';
import Flash from '~/flash';
import NavigationTabs from '~/vue_shared/components/navigation_tabs.vue';
import eventHub from '../eventhub';
import DeployKeysService from '../service';
import DeployKeysStore from '../store';
import KeysPanel from './keys_panel.vue';
import { GlLoadingIcon } from '@gitlab/ui';

export default {
  components: {
    KeysPanel,
    NavigationTabs,
    GlLoadingIcon,
  },
  props: {
    endpoint: {
      type: String,
      required: true,
    },
    projectId: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      currentTab: 'enabled_keys',
      isLoading: false,
      store: new DeployKeysStore(),
    };
  },
  scopes: {
    enabled_keys: s__('DeployKeys|Enabled deploy keys'),
    available_project_keys: s__('DeployKeys|Privately accessible deploy keys'),
    public_keys: s__('DeployKeys|Publicly accessible deploy keys'),
  },
  computed: {
    tabs() {
      return Object.keys(this.$options.scopes).map(scope => {
        const count = Array.isArray(this.keys[scope]) ? this.keys[scope].length : null;

        return {
          name: this.$options.scopes[scope],
          scope,
          isActive: scope === this.currentTab,
          count,
        };
      });
    },
    hasKeys() {
      return Object.keys(this.keys).length;
    },
    keys() {
      return this.store.keys;
    },
  },
  created() {
    this.service = new DeployKeysService(this.endpoint);

    eventHub.$on('enable.key', this.enableKey);
    eventHub.$on('remove.key', this.disableKey);
    eventHub.$on('disable.key', this.disableKey);
  },
  mounted() {
    this.fetchKeys();
  },
  beforeDestroy() {
    eventHub.$off('enable.key', this.enableKey);
    eventHub.$off('remove.key', this.disableKey);
    eventHub.$off('disable.key', this.disableKey);
  },
  methods: {
    onChangeTab(tab) {
      this.currentTab = tab;
    },
    fetchKeys() {
      this.isLoading = true;

      return this.service
        .getKeys()
        .then(data => {
          this.isLoading = false;
          this.store.keys = data;
        })
        .catch(() => {
          this.isLoading = false;
          this.store.keys = {};
          return new Flash(s__('DeployKeys|Error getting deploy keys'));
        });
    },
    enableKey(deployKey) {
      this.service
        .enableKey(deployKey.id)
        .then(this.fetchKeys)
        .catch(() => new Flash(s__('DeployKeys|Error enabling deploy key')));
    },
    disableKey(deployKey, callback) {
      if (
        // eslint-disable-next-line no-alert
        window.confirm(s__('DeployKeys|You are going to remove this deploy key. Are you sure?'))
      ) {
        this.service
          .disableKey(deployKey.id)
          .then(this.fetchKeys)
          .then(callback)
          .catch(() => new Flash(s__('DeployKeys|Error removing deploy key')));
      } else {
        callback();
      }
    },
  },
};
</script>

<template>
  <div class="append-bottom-default deploy-keys">
    <gl-loading-icon
      v-if="isLoading && !hasKeys"
      :label="s__('DeployKeys|Loading deploy keys')"
      :size="2"
    />
    <template v-else-if="hasKeys">
      <div class="top-area scrolling-tabs-container inner-page-scroll-tabs">
        <div class="fade-left"><i class="fa fa-angle-left" aria-hidden="true"> </i></div>
        <div class="fade-right"><i class="fa fa-angle-right" aria-hidden="true"> </i></div>

        <navigation-tabs :tabs="tabs" scope="deployKeys" @onChangeTab="onChangeTab" />
      </div>
      <keys-panel
        :project-id="projectId"
        :keys="keys[currentTab]"
        :store="store"
        :endpoint="endpoint"
        data-qa-selector="project_deploy_keys"
      />
    </template>
  </div>
</template>
