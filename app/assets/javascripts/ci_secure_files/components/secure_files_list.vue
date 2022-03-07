<script>
import { GlLink, GlLoadingIcon, GlPagination, GlTable } from '@gitlab/ui';
import Api, { DEFAULT_PER_PAGE } from '~/api';
import { helpPagePath } from '~/helpers/help_page_helper';
import { __ } from '~/locale';
import TimeagoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';

export default {
  components: {
    GlLink,
    GlLoadingIcon,
    GlPagination,
    GlTable,
    TimeagoTooltip,
  },
  inject: ['projectId'],
  docsLink: helpPagePath('ci/secure_files/index'),
  DEFAULT_PER_PAGE,
  i18n: {
    pagination: {
      next: __('Next'),
      prev: __('Prev'),
    },
    title: __('Secure Files'),
    overviewMessage: __(
      'Use Secure Files to store files used by your pipelines such as Android keystores, or Apple provisioning profiles and signing certificates.',
    ),
    moreInformation: __('More information'),
  },
  data() {
    return {
      page: 1,
      totalItems: 0,
      loading: false,
      projectSecureFiles: [],
    };
  },
  fields: [
    {
      key: 'name',
      label: __('Filename'),
    },
    {
      key: 'permissions',
      label: __('Permissions'),
    },
    {
      key: 'created_at',
      label: __('Uploaded'),
    },
  ],
  computed: {
    fields() {
      return this.$options.fields;
    },
  },
  watch: {
    page(newPage) {
      this.getProjectSecureFiles(newPage);
    },
  },
  created() {
    this.getProjectSecureFiles();
  },
  methods: {
    async getProjectSecureFiles(page) {
      this.loading = true;
      const response = await Api.projectSecureFiles(this.projectId, { page });

      this.totalItems = parseInt(response.headers?.['x-total'], 10) || 0;

      this.projectSecureFiles = response.data;

      this.loading = false;
    },
  },
};
</script>

<template>
  <div>
    <h1 data-testid="title" class="gl-font-size-h1 gl-mt-3 gl-mb-0">{{ $options.i18n.title }}</h1>

    <p>
      <span data-testid="info-message" class="gl-mr-2">
        {{ $options.i18n.overviewMessage }}
        <gl-link :href="$options.docsLink" target="_blank">{{
          $options.i18n.moreInformation
        }}</gl-link>
      </span>
    </p>

    <gl-table
      :busy="loading"
      :fields="fields"
      :items="projectSecureFiles"
      tbody-tr-class="js-ci-secure-files-row"
      data-qa-selector="ci_secure_files_table_content"
      sort-by="key"
      sort-direction="asc"
      stacked="lg"
      table-class="text-secondary"
      show-empty
      sort-icon-left
      no-sort-reset
    >
      <template #table-busy>
        <gl-loading-icon size="lg" class="gl-my-5" />
      </template>

      <template #cell(name)="{ item }">
        {{ item.name }}
      </template>

      <template #cell(permissions)="{ item }">
        {{ item.permissions }}
      </template>

      <template #cell(created_at)="{ item }">
        <timeago-tooltip :time="item.created_at" />
      </template>
    </gl-table>
    <gl-pagination
      v-if="!loading"
      v-model="page"
      :per-page="$options.DEFAULT_PER_PAGE"
      :total-items="totalItems"
      :next-text="$options.i18n.pagination.next"
      :prev-text="$options.i18n.pagination.prev"
      align="center"
    />
  </div>
</template>
