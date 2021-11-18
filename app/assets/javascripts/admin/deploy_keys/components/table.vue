<script>
import { GlTable, GlButton } from '@gitlab/ui';

import { __ } from '~/locale';

export default {
  name: 'DeployKeysTable',
  i18n: {
    pageTitle: __('Public deploy keys'),
    newDeployKeyButtonText: __('New deploy key'),
  },
  fields: [
    {
      key: 'title',
      label: __('Title'),
    },
    {
      key: 'fingerprint',
      label: __('Fingerprint'),
    },
    {
      key: 'projects',
      label: __('Projects with write access'),
    },
    {
      key: 'created',
      label: __('Created'),
    },
    {
      key: 'actions',
      label: __('Actions'),
    },
  ],
  components: {
    GlTable,
    GlButton,
  },
  inject: ['editPath', 'deletePath', 'createPath', 'emptyStateSvgPath'],
};
</script>

<template>
  <div>
    <div class="gl-display-flex gl-justify-content-space-between gl-align-items-center gl-py-5">
      <h4 class="gl-m-0">
        {{ $options.i18n.pageTitle }}
      </h4>
      <gl-button variant="confirm" :href="createPath">{{
        $options.i18n.newDeployKeyButtonText
      }}</gl-button>
    </div>
    <gl-table :fields="$options.fields" data-testid="deploy-keys-list" />
  </div>
</template>
