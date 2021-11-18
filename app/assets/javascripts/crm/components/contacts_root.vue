<script>
import { GlLoadingIcon, GlTable } from '@gitlab/ui';
import createFlash from '~/flash';
import { s__, __ } from '~/locale';
import getGroupContactsQuery from './queries/get_group_contacts.query.graphql';

export default {
  components: {
    GlLoadingIcon,
    GlTable,
  },
  inject: ['groupFullPath'],
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
  ],
  i18n: {
    emptyText: s__('Crm|No contacts found'),
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
    />
  </div>
</template>
