<script>
import { GlModal, GlLink, GlSprintf, GlButton, GlAlert } from '@gitlab/ui';
import { helpPagePath } from '~/helpers/help_page_helper';
import { s__, __ } from '~/locale';

export default {
  components: {
    GlModal,
    GlLink,
    GlSprintf,
    GlButton,
    GlAlert,
  },
  inject: {
    reassignmentCsvPath: {
      default: '',
    },
  },
  props: {
    modalId: {
      type: String,
      required: true,
    },
  },
  docsLink: helpPagePath('user/project/import/index', {
    anchor: 'request-reassignment-by-using-a-csv-file',
  }),
  i18n: {
    description: s__(
      'UserMapping|Use a CSV file to reassign contributions from placeholder users to existing group members. This can be done in a few steps. %{linkStart}Learn more about matching users by CSV%{linkEnd}.',
    ),
  },
  primaryAction: {
    text: s__('UserMapping|Reassign'),
  },
  cancelAction: {
    text: __('Cancel'),
  },
};
</script>
<template>
  <gl-modal
    :ref="modalId"
    :modal-id="modalId"
    :title="s__('UserMapping|Reassign with CSV file')"
    :action-primary="$options.primaryAction"
    :action-cancel="$options.cancelAction"
  >
    <gl-sprintf :message="$options.i18n.description">
      <template #link="{ content }">
        <gl-link :href="$options.docsLink" target="_blank">
          {{ content }}
        </gl-link>
      </template>
    </gl-sprintf>
    <ol class="gl-ml-0 gl-mt-5">
      <li>
        <gl-button
          :href="reassignmentCsvPath"
          variant="link"
          icon="download"
          data-testid="csv-download-button"
          class="vertical-align-text-top"
          >{{ s__('UserMapping|Download the pre-filled CSV template.') }}</gl-button
        >
      </li>
      <li>{{ s__('UserMapping|Review and complete filling out the CSV file.') }}</li>
      <li>{{ s__('UserMapping|Upload reviewed and completed CSV file.') }}</li>
    </ol>
    <gl-alert variant="warning" :dismissible="false">
      {{
        s__(
          'UserMapping|Once you select "Reassign", the processing will start and users will receive and email to accept the contribution reassignment. Once a users has accepted the reassignment, it cannot be undone. Check all data is correct before continuing.',
        )
      }}
    </gl-alert>
  </gl-modal>
</template>
