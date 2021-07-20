<script>
import { GlLoadingIcon, GlIcon } from '@gitlab/ui';
import createFlash from '~/flash';
import { s__ } from '~/locale';
import NavigationTabs from '~/vue_shared/components/navigation_tabs.vue';
import eventHub from '../eventhub';
import DeployKeysService from '../service';
import DeployKeysStore from '../store';
import ConfirmModal from './confirm_modal.vue';
import KeysPanel from './keys_panel.vue';

export default {
  components: {
    ConfirmModal,
    KeysPanel,
    NavigationTabs,
    GlLoadingIcon,
    GlIcon,
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
      removeKey: () => {},
      cancel: () => {},
      confirmModalVisible: false,
    };
  },
  scopes: {
    enabled_keys: s__('DeployKeys|Enabled deploy keys'),
    available_project_keys: s__('DeployKeys|Privately accessible deploy keys'),
    public_keys: s__('DeployKeys|Publicly accessible deploy keys'),
  },
  computed: {
    tabs() {
      return Object.keys(this.$options.scopes).map((scope) => {
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
    eventHub.$on('remove.key', this.confirmRemoveKey);
    eventHub.$on('disable.key', this.confirmRemoveKey);
  },
  mounted() {
    this.fetchKeys();
  },
  beforeDestroy() {
    eventHub.$off('enable.key', this.enableKey);
    eventHub.$off('remove.key', this.confirmRemoveKey);
    eventHub.$off('disable.key', this.confirmRemoveKey);
  },
  methods: {
    onChangeTab(tab) {
      this.currentTab = tab;
    },
    fetchKeys() {
      this.isLoading = true;

      return this.service
        .getKeys()
        .then((data) => {
          this.isLoading = false;
          this.store.keys = data;
        })
        .catch(() => {
          this.isLoading = false;
          this.store.keys = {};
          return createFlash({
            message: s__('DeployKeys|Error getting deploy keys'),
          });
        });
    },
    enableKey(deployKey) {
      this.service
        .enableKey(deployKey.id)
        .then(this.fetchKeys)
        .catch(() =>
          createFlash({
            message: s__('DeployKeys|Error enabling deploy key'),
          }),
        );
    },
    confirmRemoveKey(deployKey, callback) {
      const hideModal = () => {
        this.confirmModalVisible = false;
        callback?.();
      };
      this.removeKey = () => {
        this.service
          .disableKey(deployKey.id)
          .then(this.fetchKeys)
          .then(hideModal)
          .catch(() =>
            createFlash({
              message: s__('DeployKeys|Error removing deploy key'),
            }),
          );
      };
      this.cancel = hideModal;
      this.confirmModalVisible = true;
    },
  },
};
</script>

<template>
  <div class="gl-mb-3 deploy-keys">
    <confirm-modal :visible="confirmModalVisible" @remove="removeKey" @cancel="cancel" />
    <gl-loading-icon
      v-if="isLoading && !hasKeys"
      :label="s__('DeployKeys|Loading deploy keys')"
      size="lg"
    />
    <template v-else-if="hasKeys">
      <div class="top-area scrolling-tabs-container inner-page-scroll-tabs">
        <div class="fade-left">
          <gl-icon name="chevron-lg-left" :size="12" />
        </div>
        <div class="fade-right">
          <gl-icon name="chevron-lg-right" :size="12" />
        </div>

        <navigation-tabs :tabs="tabs" scope="deployKeys" @onChangeTab="onChangeTab" />
      </div>
      <keys-panel
        :project-id="projectId"
        :keys="keys[currentTab]"
        :store="store"
        :endpoint="endpoint"
        data-qa-selector="project_deploy_keys_container"
      />
    </template>
  </div>
</template>
