<script>
import { GlLoadingIcon, GlButton, GlEmptyState } from '@gitlab/ui';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import { getProjectRepositoryHealth } from '~/rest_api';
import { s__ } from '~/locale';
import { createAlert } from '~/alert';

export default {
  name: 'RepositoryHealthDetailsSection',
  components: {
    GlLoadingIcon,
    GlButton,
    GlEmptyState,
  },
  props: {
    repository: {
      type: Object,
      required: false,
      default: null,
    },
  },
  data() {
    return {
      loading: false,
      healthDetails: null,
    };
  },
  computed: {
    projectId() {
      if (!this.repository?.project) {
        return null;
      }

      return getIdFromGraphQLId(this.repository.project.id);
    },
  },
  created() {
    this.fetchRepositoryHealth();
  },
  methods: {
    async fetchRepositoryHealth(params = {}) {
      if (!this.projectId) {
        return;
      }

      try {
        this.loading = true;
        this.healthDetails = convertObjectPropsToCamelCase(
          (await getProjectRepositoryHealth(this.projectId, params))?.data,
          { deep: true },
        );
      } catch (e) {
        // 404 is the default response if a Health Report hasn't been generated yet.
        if (e.response?.status === 404) return;

        createAlert({
          message: s__('UsageQuota|Failed to fetch repository health, try again later.'),
          captureError: true,
          error: e,
        });
      } finally {
        this.loading = false;
      }
    },
  },
};
</script>

<template>
  <section>
    <template v-if="!projectId">
      <p class="gl-mb-0">{{ s__('UsageQuota|Failed to parse Project ID from Repository.') }}</p>
    </template>
    <gl-loading-icon v-else-if="loading" />
    <gl-empty-state
      v-else-if="!healthDetails"
      :title="s__('UsageQuota|Repository Health report was not found')"
      :description="
        s__('UsageQuota|You can generate a new report at any time by clicking the button below.')
      "
      illustration-name="status-nothing-md"
    >
      <template #actions>
        <gl-button variant="confirm" @click="fetchRepositoryHealth({ generate: true })">{{
          s__('UsageQuota|Generate Report')
        }}</gl-button>
      </template>
    </gl-empty-state>
    <template v-else>
      {{ healthDetails }}
    </template>
  </section>
</template>
