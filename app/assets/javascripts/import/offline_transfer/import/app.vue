<script>
export default {
  name: 'OfflineTransferImportApp',
};
</script>

<template>
  <header class="gl-my-5">
    <h1 class="gl-heading-display">
      {{ s__('OfflineTransferImport|Import an offline transfer') }}
    </h1>
    <p class="gl-max-w-2xl">
      {{
        s__(
          'OfflineTransferImport|Import groups and projects from a previously exported offline transfer.',
        )
      }}
    </p>
  </header>
</template>
