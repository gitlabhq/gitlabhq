<script>
import { GlAlert, GlLink, GlSprintf } from '@gitlab/ui';
import { helpPagePath } from '~/helpers/help_page_helper';
import { getTransferLocations, transferProject } from '~/api/projects_api';
import { s__, sprintf } from '~/locale';
import { createAlert } from '~/alert';
import TransferModal from '~/groups_projects/components/transfer_modal.vue';

export default {
  name: 'TransferProjectModal',
  components: {
    TransferModal,
    GlAlert,
    GlLink,
    GlSprintf,
  },
  provide() {
    return {
      resourceId: String(this.project.id),
      resourcePath: this.project.path,
      resourceFullPath: this.project.fullPath,
    };
  },
  model: {
    prop: 'visible',
    event: 'change',
  },
  props: {
    visible: {
      type: Boolean,
      required: true,
    },
    project: {
      type: Object,
      required: true,
    },
  },
  emits: ['change', 'success'],
  computed: {
    title() {
      return sprintf(s__('NamespaceTransfer|Transfer - %{name}'), { name: this.project.name });
    },
  },
  methods: {
    handleError(error) {
      createAlert({
        message:
          error ||
          s__(
            'NamespaceTransfer|An error occurred while transferring the project. Please refresh the page to try again.',
          ),
        captureError: true,
        error,
      });
    },
  },
  getTransferLocations,
  transferProject,
  transferDocsPath: helpPagePath('user/project/working_with_projects', {
    anchor: 'transfer-a-project',
  }),
};
</script>

<template>
  <transfer-modal
    :visible="visible"
    :title="title"
    :group-transfer-locations-api-method="$options.getTransferLocations"
    :transfer-api-method="$options.transferProject"
    :show-user-transfer-locations="true"
    @change="$emit('change', $event)"
    @success="$emit('success')"
    @error="handleError"
  >
    <template #body>
      <gl-alert
        variant="info"
        :title="s__('NamespaceTransfer|Transferring this project will:')"
        :dismissible="false"
        class="gl-mb-5"
      >
        <ul class="gl-mb-0 gl-pl-5">
          <li>{{ s__('NamespaceTransfer|Change its repository URL path.') }}</li>
          <li>
            {{
              s__('NamespaceTransfer|Change its visibility settings to match the new namespace.')
            }}
          </li>
        </ul>
      </gl-alert>
      <p>
        <gl-sprintf
          :message="
            s__(
              'NamespaceTransfer|Transfer this project to a different namespace. %{linkStart}How does project transfer work?%{linkEnd}',
            )
          "
        >
          <template #link="{ content }">
            <gl-link :href="$options.transferDocsPath" target="_blank">{{ content }}</gl-link>
          </template>
        </gl-sprintf>
      </p>
    </template>
  </transfer-modal>
</template>
