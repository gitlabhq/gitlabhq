<script>
import { GlAlert, GlButton, GlLoadingIcon, GlTable, GlTooltipDirective } from '@gitlab/ui';
import { parseBoolean } from '~/lib/utils/common_utils';
import { s__, __ } from '~/locale';
import { convertToGraphQLId, getIdFromGraphQLId } from '~/graphql_shared/utils';
import { TYPE_CRM_CONTACT } from '~/graphql_shared/constants';
import { INDEX_ROUTE_NAME, NEW_ROUTE_NAME, EDIT_ROUTE_NAME } from '../constants';
import getGroupContactsQuery from './queries/get_group_contacts.query.graphql';
import ContactForm from './contact_form.vue';

export default {
  components: {
    GlAlert,
    GlButton,
    GlLoadingIcon,
    GlTable,
    ContactForm,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  inject: ['groupFullPath', 'groupIssuesPath', 'canAdminCrmContact'],
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
    showNewForm() {
      return this.$route.name === NEW_ROUTE_NAME;
    },
    showEditForm() {
      return !this.isLoading && this.$route.name === EDIT_ROUTE_NAME;
    },
    canAdmin() {
      return parseBoolean(this.canAdminCrmContact);
    },
    editingContact() {
      return this.contacts.find(
        (contact) => contact.id === convertToGraphQLId(TYPE_CRM_CONTACT, this.$route.params.id),
      );
    },
  },
  methods: {
    extractContacts(data) {
      const contacts = data?.group?.contacts?.nodes || [];
      return contacts.slice().sort((a, b) => a.firstName.localeCompare(b.firstName));
    },
    displayNewForm() {
      if (this.showNewForm) return;

      this.$router.push({ name: NEW_ROUTE_NAME });
    },
    hideNewForm(success) {
      if (success) this.$toast.show(s__('Crm|Contact has been added'));

      this.$router.replace({ name: INDEX_ROUTE_NAME });
    },
    hideEditForm(success) {
      if (success) this.$toast.show(s__('Crm|Contact has been updated'));

      this.editingContactId = 0;
      this.$router.replace({ name: INDEX_ROUTE_NAME });
    },
    getIssuesPath(path, value) {
      return `${path}?scope=all&state=opened&crm_contact_id=${value}`;
    },
    edit(value) {
      if (this.showEditForm) return;

      this.editingContactId = value;
      this.$router.push({ name: EDIT_ROUTE_NAME, params: { id: value } });
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
    title: s__('Crm|Customer Relations Contacts'),
    newContact: s__('Crm|New contact'),
    errorText: __('Something went wrong. Please try again.'),
  },
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
      <div class="gl-display-none gl-md-display-flex gl-align-items-center gl-justify-content-end">
        <gl-button
          v-if="canAdmin"
          variant="confirm"
          data-testid="new-contact-button"
          @click="displayNewForm"
        >
          {{ $options.i18n.newContact }}
        </gl-button>
      </div>
    </div>
    <contact-form v-if="showNewForm" :drawer-open="showNewForm" @close="hideNewForm" />
    <contact-form
      v-if="showEditForm"
      :contact="editingContact"
      :drawer-open="showEditForm"
      @close="hideEditForm"
    />
    <gl-loading-icon v-if="isLoading" class="gl-mt-5" size="lg" />
    <gl-table
      v-else
      class="gl-mt-5"
      :items="contacts"
      :fields="$options.fields"
      :empty-text="$options.i18n.emptyText"
      show-empty
    >
      <template #cell(id)="data">
        <gl-button
          v-gl-tooltip.hover.bottom="$options.i18n.issuesButtonLabel"
          class="gl-mr-3"
          data-testid="issues-link"
          icon="issues"
          :aria-label="$options.i18n.issuesButtonLabel"
          :href="getIssuesPath(groupIssuesPath, data.value)"
        />
        <gl-button
          v-if="canAdmin"
          v-gl-tooltip.hover.bottom="$options.i18n.editButtonLabel"
          data-testid="edit-contact-button"
          icon="pencil"
          :aria-label="$options.i18n.editButtonLabel"
          @click="edit(data.value)"
        />
      </template>
    </gl-table>
  </div>
</template>
