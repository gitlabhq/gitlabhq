<script>
import { GlModal } from '@gitlab/ui';
import { __, s__, sprintf } from '~/locale';
import Api from '~/api';
import LocalStorageSync from '~/vue_shared/components/local_storage_sync.vue';

import EditMetaControls from './edit_meta_controls.vue';

import { ISSUABLE_TYPE, MR_META_LOCAL_STORAGE_KEY } from '../constants';

export default {
  components: {
    GlModal,
    EditMetaControls,
    LocalStorageSync,
  },
  props: {
    sourcePath: {
      type: String,
      required: true,
    },
    namespace: {
      type: String,
      required: true,
    },
    project: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      clearStorage: false,
      currentTemplate: null,
      mergeRequestTemplates: null,
      mergeRequestMeta: {
        title: sprintf(s__(`StaticSiteEditor|Update %{sourcePath} file`), {
          sourcePath: this.sourcePath,
        }),
        description: s__('StaticSiteEditor|Copy update'),
      },
    };
  },
  computed: {
    disabled() {
      return this.mergeRequestMeta.title === '';
    },
    primaryProps() {
      return {
        text: __('Submit changes'),
        attributes: [{ variant: 'success' }, { disabled: this.disabled }],
      };
    },
    secondaryProps() {
      return {
        text: __('Keep editing'),
        attributes: [{ variant: 'default' }],
      };
    },
  },
  mounted() {
    this.initTemplates();
  },
  methods: {
    hide() {
      this.$refs.modal.hide();
    },
    initTemplates() {
      const { namespace, project } = this;
      Api.issueTemplates(namespace, project, ISSUABLE_TYPE, (err, templates) => {
        if (err) return; // Error handled by global AJAX error handler
        this.mergeRequestTemplates = templates;
      });
    },
    show() {
      this.$refs.modal.show();
    },
    onPrimary() {
      this.$emit('primary', this.mergeRequestMeta);
      this.clearStorage = true;
    },
    onSecondary() {
      this.hide();
    },
    onChangeTemplate(template) {
      this.currentTemplate = template;

      const description = this.currentTemplate ? this.currentTemplate.content : '';
      const mergeRequestMeta = { ...this.mergeRequestMeta, description };
      this.onUpdateSettings(mergeRequestMeta);
    },
    onUpdateSettings(mergeRequestMeta) {
      this.mergeRequestMeta = { ...mergeRequestMeta };
    },
  },
  storageKey: MR_META_LOCAL_STORAGE_KEY,
};
</script>

<template>
  <gl-modal
    ref="modal"
    modal-id="edit-meta-modal"
    :title="__('Submit your changes')"
    :action-primary="primaryProps"
    :action-secondary="secondaryProps"
    size="sm"
    @primary="onPrimary"
    @secondary="onSecondary"
    @hide="() => $emit('hide')"
  >
    <local-storage-sync
      v-model="mergeRequestMeta"
      :storage-key="$options.storageKey"
      :clear="clearStorage"
      as-json
    />
    <edit-meta-controls
      ref="editMetaControls"
      :title="mergeRequestMeta.title"
      :description="mergeRequestMeta.description"
      :templates="mergeRequestTemplates"
      :current-template="currentTemplate"
      @updateSettings="onUpdateSettings"
      @changeTemplate="onChangeTemplate"
    />
  </gl-modal>
</template>
