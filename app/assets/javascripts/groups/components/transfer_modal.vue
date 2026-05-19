<script>
import { GlAlert, GlLink, GlSprintf } from '@gitlab/ui';
import { helpPagePath } from '~/helpers/help_page_helper';
import { getGroupTransferLocations, transferGroup } from '~/api/groups_api';
import { __, s__, sprintf } from '~/locale';
import { createAlert } from '~/alert';
import TransferModal from '~/groups_projects/components/transfer_modal.vue';

export default {
  name: 'TransferGroupModal',
  components: {
    TransferModal,
    GlAlert,
    GlLink,
    GlSprintf,
  },
  provide() {
    return {
      resourceId: String(this.group.id),
      resourcePath: this.group.path,
      resourceFullPath: this.group.fullPath,
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
    group: {
      type: Object,
      required: true,
    },
  },
  emits: ['change', 'success'],
  computed: {
    additionalDropdownItems() {
      return [
        {
          id: null,
          humanName: __('No parent group'),
          newPath: this.group.path,
        },
      ];
    },
    title() {
      return sprintf(s__('NamespaceTransfer|Transfer - %{name}'), { name: this.group.name });
    },
  },
  methods: {
    handleError(error) {
      createAlert({
        message:
          error ||
          s__(
            'NamespaceTransfer|An error occurred while transferring the group. Please refresh the page to try again.',
          ),
        captureError: true,
        error,
      });
    },
  },
  getGroupTransferLocations,
  transferGroup,
  transferDocsPath: helpPagePath('user/group/manage', { anchor: 'transfer-a-group' }),
};
</script>

<template>
  <transfer-modal
    :visible="visible"
    :title="title"
    :group-transfer-locations-api-method="$options.getGroupTransferLocations"
    :transfer-api-method="$options.transferGroup"
    :show-user-transfer-locations="false"
    :additional-dropdown-items="additionalDropdownItems"
    @change="$emit('change', $event)"
    @success="$emit('success')"
    @error="handleError"
  >
    <template #body>
      <gl-alert
        variant="info"
        :title="s__('NamespaceTransfer|Transferring this group will:')"
        :dismissible="false"
        class="gl-mb-5"
      >
        <ul class="gl-mb-0 gl-pl-5">
          <li>{{ s__('NamespaceTransfer|Change its repository URL paths.') }}</li>
          <li>
            {{
              s__('NamespaceTransfer|Change its visibility settings to match the new parent group.')
            }}
          </li>
        </ul>
      </gl-alert>
      <p>
        <gl-sprintf
          :message="
            s__(
              'NamespaceTransfer|Transfer this group and all its projects to a different parent group, or convert it to a top-level group. %{linkStart}How does group transfer work?%{linkEnd}',
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
