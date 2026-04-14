<script>
export default {
  name: 'OfflineTransferExportApp',
};
</script>

<template>
  <header class="gl-my-5">
    <h1 class="gl-heading-display">
      {{ s__('OfflineTransferExport|Export for offline transfer') }}
    </h1>
    <p class="gl-max-w-2xl">
      {{
        s__(
          'OfflineTransferExport|Export your groups and projects to an object storage service you control. You can import the groups and projects to any GitLab instance, even with no network connection between this instance and the destination instance.',
        )
      }}
    </p>
  </header>
</template>
