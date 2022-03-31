<script>
import { GlAlert, GlButton, GlLoadingIcon, GlTable, GlTooltipDirective } from '@gitlab/ui';
import { parseBoolean } from '~/lib/utils/common_utils';
import { s__, __ } from '~/locale';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { EDIT_ROUTE_NAME, NEW_ROUTE_NAME } from '../../constants';
import getGroupContactsQuery from './graphql/get_group_contacts.query.graphql';

export default {
  components: {
    GlAlert,
    GlButton,
    GlLoadingIcon,
    GlTable,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  inject: ['canAdminCrmContact', 'groupFullPath', 'groupIssuesPath'],
  data() {
    return {
      contacts: [],
      error: false,
    };
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
      error() {
        this.error = true;
      },
    },
  },
  computed: {
    isLoading() {
      return this.$apollo.queries.contacts.loading;
    },
    canAdmin() {
      return parseBoolean(this.canAdminCrmContact);
    },
  },
  methods: {
    extractContacts(data) {
      const contacts = data?.group?.contacts?.nodes || [];
      return contacts.slice().sort((a, b) => a.firstName.localeCompare(b.firstName));
    },
    getIssuesPath(path, value) {
      return `${path}?scope=all&state=opened&crm_contact_id=${value}`;
    },
    getEditRoute(id) {
      return { name: this.$options.EDIT_ROUTE_NAME, params: { id } };
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
      label: '',
      formatter: (id) => {
        return getIdFromGraphQLId(id);
      },
    },
  ],
  i18n: {
    emptyText: s__('Crm|No contacts found'),
    issuesButtonLabel: __('View issues'),
    editButtonLabel: __('Edit'),
    title: s__('Crm|Customer relations contacts'),
    newContact: s__('Crm|New contact'),
    errorText: __('Something went wrong. Please try again.'),
  },
  EDIT_ROUTE_NAME,
  NEW_ROUTE_NAME,
};
</script>

<template>
  <div>
    <gl-alert v-if="error" variant="danger" class="gl-mt-6" @dismiss="error = false">
      {{ $options.i18n.errorText }}
    </gl-alert>
    <div
      class="gl-display-flex gl-align-items-baseline gl-flex-direction-row gl-justify-content-space-between gl-mt-6"
    >
      <h2 class="gl-font-size-h2 gl-my-0">
        {{ $options.i18n.title }}
      </h2>
      <div v-if="canAdmin">
        <router-link :to="{ name: $options.NEW_ROUTE_NAME }">
          <gl-button variant="confirm" data-testid="new-contact-button">
            {{ $options.i18n.newContact }}
          </gl-button>
        </router-link>
      </div>
    </div>
    <router-view />
    <gl-loading-icon v-if="isLoading" class="gl-mt-5" size="lg" />
    <gl-table
      v-else
      class="gl-mt-5"
      :items="contacts"
      :fields="$options.fields"
      :empty-text="$options.i18n.emptyText"
      show-empty
    >
      <template #cell(id)="{ value: id }">
        <gl-button
          v-gl-tooltip.hover.bottom="$options.i18n.issuesButtonLabel"
          class="gl-mr-3"
          data-testid="issues-link"
          icon="issues"
          :aria-label="$options.i18n.issuesButtonLabel"
          :href="getIssuesPath(groupIssuesPath, id)"
        />
        <router-link :to="getEditRoute(id)">
          <gl-button
            v-if="canAdmin"
            v-gl-tooltip.hover.bottom="$options.i18n.editButtonLabel"
            data-testid="edit-contact-button"
            icon="pencil"
            :aria-label="$options.i18n.editButtonLabel"
          />
        </router-link>
      </template>
    </gl-table>
  </div>
</template>
