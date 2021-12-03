<script>
import { GlButton, GlLoadingIcon, GlTable, GlTooltipDirective } from '@gitlab/ui';
import createFlash from '~/flash';
import { s__, __ } from '~/locale';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import getGroupContactsQuery from './queries/get_group_contacts.query.graphql';

export default {
  components: {
    GlButton,
    GlLoadingIcon,
    GlTable,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  inject: ['groupFullPath', 'groupIssuesPath'],
  data() {
    return { contacts: [] };
  },
  apollo: {
    contacts: {
      query() {
        return getGroupContactsQuery;
      },
      variables() {
        return {
          groupFullPath: this.groupFullPath,
        };
      },
      update(data) {
        return this.extractContacts(data);
      },
      error(error) {
        createFlash({
          message: __('Something went wrong. Please try again.'),
          error,
          captureError: true,
        });
      },
    },
  },
  computed: {
    isLoading() {
      return this.$apollo.queries.contacts.loading;
    },
  },
  methods: {
    extractContacts(data) {
      const contacts = data?.group?.contacts?.nodes || [];
      return contacts.slice().sort((a, b) => a.firstName.localeCompare(b.firstName));
    },
  },
  fields: [
    { key: 'firstName', sortable: true },
    { key: 'lastName', sortable: true },
    { key: 'email', sortable: true },
    { key: 'phone', sortable: true },
    { key: 'description', sortable: true },
    {
      key: 'organization',
      formatter: (organization) => {
        return organization?.name;
      },
      sortable: true,
    },
    {
      key: 'id',
      label: __('Issues'),
      formatter: (id) => {
        return getIdFromGraphQLId(id);
      },
    },
  ],
  i18n: {
    emptyText: s__('Crm|No contacts found'),
    issuesButtonLabel: __('View issues'),
  },
};
</script>

<template>
  <div>
    <gl-loading-icon v-if="isLoading" class="gl-mt-5" size="lg" />
    <gl-table
      v-else
      :items="contacts"
      :fields="$options.fields"
      :empty-text="$options.i18n.emptyText"
      show-empty
    >
      <template #cell(id)="data">
        <gl-button
          v-gl-tooltip.hover.bottom="$options.i18n.issuesButtonLabel"
          data-testid="issues-link"
          icon="issues"
          :aria-label="$options.i18n.issuesButtonLabel"
          :href="`${groupIssuesPath}?scope=all&state=opened&crm_contact_id=${data.value}`"
        />
      </template>
    </gl-table>
  </div>
</template>
