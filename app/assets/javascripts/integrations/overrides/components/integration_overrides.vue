<script>
import { GlLink, GlLoadingIcon, GlPagination, GlTable, GlAlert } from '@gitlab/ui';
import * as Sentry from '~/sentry/sentry_browser_wrapper';

import { DEFAULT_PER_PAGE } from '~/api';
import { fetchOverrides } from '~/integrations/overrides/api';
import { parseIntPagination, normalizeHeaders } from '~/lib/utils/common_utils';
import { truncateNamespace } from '~/lib/utils/text_utility';
import { getParameterByName } from '~/lib/utils/url_utility';
import { __, s__ } from '~/locale';
import ProjectAvatar from '~/vue_shared/components/project_avatar.vue';
import UrlSync from '~/vue_shared/components/url_sync.vue';

import IntegrationTabs from './integration_tabs.vue';

const DEFAULT_PAGE = 1;

export default {
  name: 'IntegrationOverrides',
  components: {
    GlLink,
    GlLoadingIcon,
    GlPagination,
    GlTable,
    GlAlert,
    ProjectAvatar,
    UrlSync,
    IntegrationTabs,
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
      page: DEFAULT_PAGE,
      totalItems: 0,
      errorMessage: null,
    };
  },
  computed: {
    overridesCount() {
      return this.isLoading ? null : this.totalItems;
    },
    showPagination() {
      return this.totalItems > this.$options.DEFAULT_PER_PAGE && this.overrides.length > 0;
    },
    query() {
      return {
        page: this.page,
      };
    },
  },
  created() {
    const initialPage = this.getInitialPage();
    this.loadOverrides(initialPage);
  },
  methods: {
    getInitialPage() {
      return getParameterByName('page') ?? DEFAULT_PAGE;
    },
    loadOverrides(page) {
      this.isLoading = true;
      this.errorMessage = null;

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
          this.errorMessage = this.$options.i18n.defaultErrorMessage;

          Sentry.captureException(error);
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
    <integration-tabs :project-overrides-count="overridesCount" />
    <gl-alert v-if="errorMessage" variant="danger" :dismissible="false">
      {{ errorMessage }}
    </gl-alert>
    <gl-table
      v-else
      :items="overrides"
      :fields="$options.fields"
      :busy="isLoading"
      show-empty
      :empty-text="$options.i18n.tableEmptyText"
    >
      <template #cell(name)="{ item }">
        <gl-link
          class="gl-inline-flex gl-items-center !gl-text-default hover:gl-no-underline"
          :href="item.full_path"
        >
          <project-avatar
            class="gl-mr-3"
            :project-id="item.id"
            :project-avatar-url="item.avatar_url"
            :project-name="item.name"
            aria-hidden="true"
          />
          {{ truncateNamespace(item.full_name) }} /&nbsp;

          <strong>{{ item.name }}</strong>
        </gl-link>
      </template>

      <template #table-busy>
        <gl-loading-icon size="lg" class="gl-my-2" />
      </template>
    </gl-table>
    <div class="gl-mt-5 gl-flex gl-justify-center">
      <template v-if="showPagination">
        <gl-pagination
          :per-page="$options.DEFAULT_PER_PAGE"
          :total-items="totalItems"
          :value="page"
          :disabled="isLoading"
          @input="loadOverrides"
        />
        <url-sync :query="query" />
      </template>
    </div>
  </div>
</template>
