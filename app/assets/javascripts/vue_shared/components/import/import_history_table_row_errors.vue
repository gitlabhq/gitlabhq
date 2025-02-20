<script>
import { GlAlert, GlLink } from '@gitlab/ui';

/**
 * Error formatter for import table items
 */
export default {
  name: 'ImportHistoryTableRowErrors',
  components: {
    GlAlert,
    GlLink,
  },
  props: {
    /**
     * Should accept data as it comes from the BulkImport API endpoint.
     *
     * Also accepts some additional optional fields in each entry in the `failures` array:
     * - `link_text`: string to override the default "Learn more".
     * - `raw`: raw error output, which is displayed in a code block if provided.
     */
    item: {
      type: Object,
      required: true,
    },
    /** The path for error detail links. Can be injected in parent. */
    detailsPath: {
      type: String,
      required: false,
      default: null,
    },
  },
};
</script>

<template>
  <div class="gl-flex gl-flex-col gl-gap-5">
    <div
      v-for="failure in item.failures"
      :key="failure.correlation_id_value"
      data-testid="import-history-table-row-error"
    >
      <gl-alert variant="danger" :dismissible="false">
        {{ failure.exception_message }}
        <gl-link :href="detailsPath">{{ failure.link_text || __('Learn more') }}</gl-link>
      </gl-alert>
      <pre
        v-if="failure.raw"
        class="gl-mt-5 gl-border-0 gl-p-0"
      ><code v-if="failure.raw" data-testid="import-history-table-row-error-raw" class="gl-bg-inherit">{{ failure.raw }}</code></pre>
    </div>
  </div>
</template>
