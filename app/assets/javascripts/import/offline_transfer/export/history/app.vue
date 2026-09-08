<script>
import { GlEmptyState } from '@gitlab/ui';
import EMPTY_STATE_SVG_URL from '@gitlab/svgs/dist/illustrations/status/status-nothing-md.svg';

export default {
  name: 'OfflineTransferExportHistoryApp',
  components: {
    GlEmptyState,
  },
  EMPTY_STATE_SVG_URL,
};
</script>

<template>
  <div>
    <header class="gl-my-5">
      <h1 class="gl-heading-display">
        {{ s__('OfflineTransferExport|Export history') }}
      </h1>
    </header>

    <gl-empty-state
      :svg-path="$options.EMPTY_STATE_SVG_URL"
      :title="s__('OfflineTransferExport|No history is available yet')"
      :description="
        s__('OfflineTransferExport|Groups exported through offline transfer appear here.')
      "
    />
  </div>
</template>
