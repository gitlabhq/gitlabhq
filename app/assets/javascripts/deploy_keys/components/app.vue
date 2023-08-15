<script>
import { GlButton, GlIcon, GlLoadingIcon } from '@gitlab/ui';
import { createAlert } from '~/alert';
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
    GlButton,
    GlIcon,
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
  i18n: {
    loading: s__('DeployKeys|Loading deploy keys'),
    addButton: s__('DeployKeys|Add new key'),
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
          return createAlert({
            message: s__('DeployKeys|Error getting deploy keys'),
          });
        });
    },
    enableKey(deployKey) {
      this.service
        .enableKey(deployKey.id)
        .then(this.fetchKeys)
        .catch(() =>
          createAlert({
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
            createAlert({
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
  <div class="deploy-keys">
    <confirm-modal :visible="confirmModalVisible" @remove="removeKey" @cancel="cancel" />
    <gl-loading-icon
      v-if="isLoading && !hasKeys"
      :label="$options.i18n.loading"
      size="sm"
      class="gl-m-5"
    />
    <template v-else-if="hasKeys">
      <div class="gl-new-card-header gl-align-items-center gl-pt-0 gl-pb-0 gl-pl-0">
        <div class="top-area scrolling-tabs-container inner-page-scroll-tabs gl-border-b-0">
          <div class="fade-left">
            <gl-icon name="chevron-lg-left" :size="12" />
          </div>
          <div class="fade-right">
            <gl-icon name="chevron-lg-right" :size="12" />
          </div>

          <navigation-tabs
            :tabs="tabs"
            scope="deployKeys"
            class="gl-rounded-lg"
            @onChangeTab="onChangeTab"
          />
        </div>

        <div class="gl-new-card-actions">
          <gl-button
            size="small"
            class="js-toggle-button js-toggle-content"
            data-testid="add-new-deploy-key-button"
          >
            {{ $options.i18n.addButton }}
          </gl-button>
        </div>
      </div>
      <keys-panel
        :project-id="projectId"
        :keys="keys[currentTab]"
        :store="store"
        :endpoint="endpoint"
        data-testid="project-deploy-keys-container"
      />
    </template>
  </div>
</template>
