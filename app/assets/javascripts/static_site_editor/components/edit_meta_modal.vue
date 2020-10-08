<script>
import { GlModal } from '@gitlab/ui';
import { __, s__, sprintf } from '~/locale';

import EditMetaControls from './edit_meta_controls.vue';

export default {
  components: {
    GlModal,
    EditMetaControls,
  },
  props: {
    sourcePath: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
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
  },
  methods: {
    hide() {
      this.$refs.modal.hide();
    },
    show() {
      this.$refs.modal.show();
    },
    onUpdateSettings(mergeRequestMeta) {
      this.mergeRequestMeta = { ...mergeRequestMeta };
    },
  },
};
</script>

<template>
  <gl-modal
    ref="modal"
    modal-id="edit-meta-modal"
    :title="__('Submit your changes')"
    :action-primary="primaryProps"
    size="sm"
    @primary="() => $emit('primary', mergeRequestMeta)"
    @hide="() => $emit('hide')"
  >
    <edit-meta-controls
      :title="mergeRequestMeta.title"
      :description="mergeRequestMeta.description"
      @updateSettings="onUpdateSettings"
    />
  </gl-modal>
</template>
