<script>
import { GlCollapsibleListbox } from '@gitlab/ui';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import { createAlert } from '~/alert';
import { s__ } from '~/locale';
import axios from '~/lib/utils/axios_utils';

export default {
  ORGANIZATIONS_PER_PAGE: 25, // Same value as PAGE_LENGTH in `app/controllers/import/github_groups_controller.rb`
  components: {
    GlCollapsibleListbox,
  },
  inject: ['statusImportGithubGroupPath'],
  props: {
    value: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      page: 1,
      hasMoreOrganizations: false,
      isLoading: true,
      isLoadingMore: false,
      organizations: [],
      organizationFilter: '',
    };
  },
  computed: {
    toggleText() {
      return this.value || s__('ImportProjects|All organizations');
    },
    dropdownItems() {
      return [
        { text: s__('ImportProjects|All organizations'), value: '' },
        ...this.organizations
          .filter((entry) =>
            entry.name.toLowerCase().includes(this.organizationFilter.toLowerCase()),
          )
          .map((entry) => ({
            text: entry.name,
            value: entry.name,
          })),
      ];
    },
  },
  async mounted() {
    this.loadInitialOrganizations();
  },
  methods: {
    async fetchOrganizations(page = this.page) {
      try {
        const {
          data: { provider_groups: organizations },
        } = await axios.get(this.statusImportGithubGroupPath, {
          params: { page },
        });

        this.hasMoreOrganizations = organizations.length === this.$options.ORGANIZATIONS_PER_PAGE;

        return organizations;
      } catch (e) {
        createAlert({
          message: s__('GithubImporter|Something went wrong while fetching GitHub organizations.'),
        });
        Sentry.captureException(e);

        this.hasMoreOrganizations = false; // Stop loading more after error

        return [];
      }
    },
    async loadInitialOrganizations() {
      this.organizations = await this.fetchOrganizations();
      this.isLoading = false;
    },
    async loadMoreOrganizations() {
      if (!this.hasMoreOrganizations) {
        return;
      }

      this.isLoadingMore = true;
      const nextPageOrganizations = await this.fetchOrganizations(this.page + 1);
      if (nextPageOrganizations.length > 0) {
        this.organizations.push(...nextPageOrganizations);
        this.page += 1;
      }
      this.isLoadingMore = false;
    },
  },
};
</script>
<template>
  <gl-collapsible-listbox
    :loading="isLoading"
    :toggle-text="toggleText"
    :header-text="s__('ImportProjects|Organizations')"
    :items="dropdownItems"
    searchable
    :infinite-scroll="hasMoreOrganizations"
    :infinite-scroll-loading="isLoadingMore"
    role="button"
    tabindex="0"
    @search="organizationFilter = $event"
    @select="$emit('input', $event)"
    @bottom-reached="loadMoreOrganizations"
  />
</template>
