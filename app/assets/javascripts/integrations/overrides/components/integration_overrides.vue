<script>
import { GlLink, GlLoadingIcon, GlPagination, GlTable } from '@gitlab/ui';

import { DEFAULT_PER_PAGE } from '~/api';
import createFlash from '~/flash';
import { fetchOverrides } from '~/integrations/overrides/api';
import { parseIntPagination, normalizeHeaders } from '~/lib/utils/common_utils';
import { truncateNamespace } from '~/lib/utils/text_utility';
import { __, s__ } from '~/locale';
import ProjectAvatar from '~/vue_shared/components/project_avatar.vue';

export default {
  name: 'IntegrationOverrides',
  components: {
    GlLink,
    GlLoadingIcon,
    GlPagination,
    GlTable,
    ProjectAvatar,
  },
  props: {
    overridesPath: {
      type: String,
      required: true,
    },
  },
  fields: [
    {
      key: 'name',
      label: __('Project'),
    },
  ],
  data() {
    return {
      isLoading: true,
      overrides: [],
      page: 1,
      totalItems: 0,
    };
  },
  computed: {
    showPagination() {
      return this.totalItems > this.$options.DEFAULT_PER_PAGE && this.overrides.length > 0;
    },
  },
  mounted() {
    this.loadOverrides();
  },
  methods: {
    loadOverrides(page = this.page) {
      this.isLoading = true;

      fetchOverrides(this.overridesPath, {
        page,
        perPage: this.$options.DEFAULT_PER_PAGE,
      })
        .then(({ data, headers }) => {
          const { page: newPage, total } = parseIntPagination(normalizeHeaders(headers));
          this.page = newPage;
          this.totalItems = total;
          this.overrides = data;
        })
        .catch((error) => {
          createFlash({
            message: this.$options.i18n.defaultErrorMessage,
            error,
            captureError: true,
          });
        })
        .finally(() => {
          this.isLoading = false;
        });
    },
    truncateNamespace,
  },
  DEFAULT_PER_PAGE,
  i18n: {
    defaultErrorMessage: s__(
      'Integrations|An error occurred while loading projects using custom settings.',
    ),
    tableEmptyText: s__('Integrations|There are no projects using custom settings'),
  },
};
</script>

<template>
  <div>
    <gl-table
      :items="overrides"
      :fields="$options.fields"
      :busy="isLoading"
      show-empty
      :empty-text="$options.i18n.tableEmptyText"
    >
      <template #cell(name)="{ item }">
        <gl-link
          class="gl-display-inline-flex gl-align-items-center gl-hover-text-decoration-none gl-text-body!"
          :href="item.full_path"
        >
          <project-avatar
            class="gl-mr-3"
            :project-avatar-url="item.avatar_url"
            :project-name="item.name"
            aria-hidden="true"
          />
          {{ truncateNamespace(item.full_name) }} /&nbsp;

          <strong>{{ item.name }}</strong>
        </gl-link>
      </template>

      <template #table-busy>
        <gl-loading-icon size="md" class="gl-my-2" />
      </template>
    </gl-table>
    <div class="gl-display-flex gl-justify-content-center gl-mt-5">
      <gl-pagination
        v-if="showPagination"
        :per-page="$options.DEFAULT_PER_PAGE"
        :total-items="totalItems"
        :value="page"
        :disabled="isLoading"
        @input="loadOverrides"
      />
    </div>
  </div>
</template>
