<script>
import { GlModal, GlSprintf, GlLink, GlButton } from '@gitlab/ui';
// eslint-disable-next-line no-restricted-imports
import { mapState } from 'vuex';
import { __, s__, sprintf } from '~/locale';

export default {
  components: {
    GlModal,
    GlSprintf,
    GlLink,
    GlButton,
  },
  data() {
    return {
      visible: false,
    };
  },
  computed: {
    ...mapState('editNew', ['release', 'deleteReleaseDocsPath']),
    title() {
      return sprintf(__('Delete release %{release}?'), { release: this.release.name });
    },
  },
  modalOptions: {
    modalId: 'confirm-delete-release',
    static: true,
    actionPrimary: {
      attributes: { variant: 'danger' },
      text: __('Delete release'),
    },
    actionSecondary: {
      text: __('Cancel'),
      attributes: { variant: 'default' },
    },
  },
  i18n: {
    buttonLabel: __('Delete'),
    line1: s__(
      'DeleteRelease|You are about to delete release %{release} and its assets. The Git tag %{tag} will not be deleted.',
    ),
    line2: s__(
      'DeleteRelease|For more details, see %{docsPathStart}Deleting a release%{docsPathEnd}.',
    ),
    line3: s__('DeleteRelease|Are you sure you want to delete this release?'),
  },
};
</script>
<template>
  <div>
    <gl-button variant="danger" @click="visible = true">
      {{ $options.i18n.buttonLabel }}
    </gl-button>
    <gl-modal
      v-bind="$options.modalOptions"
      v-model="visible"
      :title="title"
      @primary="$emit('delete')"
    >
      <p>
        <gl-sprintf :message="$options.i18n.line1">
          <template #release>{{ release.name }}</template>
          <template #tag>
            <gl-link :href="release.tagPath">{{ release.tagName }}</gl-link>
          </template>
        </gl-sprintf>
      </p>
      <p>
        <gl-sprintf :message="$options.i18n.line2">
          <template #docsPath="{ content }">
            <gl-link :href="deleteReleaseDocsPath" target="_blank">{{ content }}</gl-link>
          </template>
        </gl-sprintf>
      </p>
      <p>{{ $options.i18n.line3 }}</p>
    </gl-modal>
  </div>
</template>
