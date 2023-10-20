<script>
import { GlCollapsibleListbox } from '@gitlab/ui';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import { createAlert } from '~/alert';
import { __, s__ } from '~/locale';
import axios from '~/lib/utils/axios_utils';

export default {
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
    return { organizationsLoading: true, organizations: [], organizationFilter: '' };
  },
  computed: {
    toggleText() {
      return this.value || this.$options.i18n.allOrganizations;
    },
    dropdownItems() {
      return [
        { text: this.$options.i18n.allOrganizations, value: '' },
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
    try {
      this.organizationsLoading = true;
      const {
        data: { provider_groups: organizations },
      } = await axios.get(this.statusImportGithubGroupPath);
      this.organizations = organizations;
    } catch (e) {
      createAlert({
        message: __('Something went wrong on our end.'),
      });
      Sentry.captureException(e);
    } finally {
      this.organizationsLoading = false;
    }
  },
  i18n: {
    allOrganizations: s__('ImportProjects|All organizations'),
  },
};
</script>
<template>
  <gl-collapsible-listbox
    :loading="organizationsLoading"
    :toggle-text="toggleText"
    :header-text="s__('ImportProjects|Organizations')"
    :items="dropdownItems"
    searchable
    role="button"
    tabindex="0"
    @search="organizationFilter = $event"
    @select="$emit('input', $event)"
  />
</template>
