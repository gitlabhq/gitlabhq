<script>
import { GlLoadingIcon } from '@gitlab/ui';
import API from '~/api';
import { createAlert } from '~/alert';
import { DEFAULT_ERROR } from '../utils/error_messages';

export default {
  components: {
    GlLoadingIcon,
  },
  props: {
    id: {
      type: Number,
      required: true,
    },
  },
  data() {
    return {
      loading: true,
      error: null,
    };
  },
  async mounted() {
    try {
      const {
        data: { import_error: importError },
      } = await API.project(this.id);
      this.error = importError;
    } catch (e) {
      createAlert({ message: DEFAULT_ERROR });
      this.error = null;
    } finally {
      this.loading = false;
    }
  },
};
</script>
<template>
  <gl-loading-icon v-if="loading" size="lg" />
  <pre
    v-else
  ><code>{{ error || s__('BulkImport|No additional information provided.') }}</code></pre>
</template>
