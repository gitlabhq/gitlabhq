<script>
export default {
  name: 'OfflineTransferApp',
};
</script>

<template>
  <header class="gl-my-5">
    <h1 class="gl-heading-display">
      {{ s__('OfflineTransfer|Offline transfer') }}
    </h1>
    <p class="gl-text-lg" data-testid="offline-transfer-subheading">
      {{
        s__(
          'OfflineTransfer|Move groups and their contents to any GitLab instance, even with no network connection between this and the destination instance. With offline transfer you can export groups to an object storage you control, then import the files into the destination instance.',
        )
      }}
    </p>
  </header>
</template>
