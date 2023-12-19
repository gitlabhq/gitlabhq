<!-- eslint-disable vue/multi-word-component-names -->
<script>
import { GlSprintf } from '@gitlab/ui';
import { s__ } from '~/locale';

import DetailsRow from '~/vue_shared/components/registry/details_row.vue';

export default {
  i18n: {
    requiredPython: s__('PackageRegistry|Required Python: %{pythonVersion}'),
    summary: s__('PackageRegistry|Summary: %{summary}'),
    authorEmail: s__('PackageRegistry|Author email: %{authorEmail}'),
    keywords: s__('PackageRegistry|Keywords: %{keywords}'),
  },
  components: {
    DetailsRow,
    GlSprintf,
  },
  props: {
    packageMetadata: {
      type: Object,
      required: true,
    },
  },
};
</script>

<template>
  <div>
    <details-row dashed icon="information-o" padding="gl-p-4" data-testid="pypi-required-python">
      <gl-sprintf :message="$options.i18n.requiredPython">
        <template #pythonVersion>
          <strong>{{ packageMetadata.requiredPython }}</strong>
        </template>
      </gl-sprintf>
    </details-row>
    <details-row dashed icon="doc-text" padding="gl-p-4" data-testid="pypi-summary">
      <gl-sprintf :message="$options.i18n.summary">
        <template #summary>
          <strong>{{ packageMetadata.summary }}</strong>
        </template>
      </gl-sprintf>
    </details-row>
    <details-row dashed icon="doc-text" padding="gl-p-4" data-testid="pypi-keywords">
      <gl-sprintf :message="$options.i18n.keywords">
        <template #keywords>
          <strong>{{ packageMetadata.keywords }}</strong>
        </template>
      </gl-sprintf>
    </details-row>
    <details-row dashed icon="mail" padding="gl-p-4" data-testid="pypi-author-email">
      <gl-sprintf :message="$options.i18n.authorEmail">
        <template #authorEmail>
          <strong>{{ packageMetadata.authorEmail }}</strong>
        </template>
      </gl-sprintf>
    </details-row>
  </div>
</template>
