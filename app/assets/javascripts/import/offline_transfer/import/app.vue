<script>
import { s__ } from '~/locale';

export default {
  name: 'OfflineTransferImportApp',
  OFFLINE_IMPORT_HEADING: s__('OfflineTransferImport|Import an offline transfer'),
  OFFLINE_IMPORT_SUBHEADING: s__(
    'OfflineTransferImport|Import groups and projects from a previously exported offline transfer.',
  ),
};
</script>

<template>
  <header class="gl-my-5">
    <h1 class="gl-heading-display">
      {{ $options.OFFLINE_IMPORT_HEADING }}
    </h1>
    <p class="gl-max-w-2xl">
      {{ $options.OFFLINE_IMPORT_SUBHEADING }}
    </p>
  </header>
</template>
