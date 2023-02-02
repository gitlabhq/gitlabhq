<script>
import { s__, __ } from '~/locale';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import { TYPENAME_CRM_CONTACT, TYPENAME_GROUP } from '~/graphql_shared/constants';
import CrmForm from '../../components/crm_form.vue';
import getGroupOrganizationsQuery from '../../organizations/components/graphql/get_group_organizations.query.graphql';
import getGroupContactsQuery from './graphql/get_group_contacts.query.graphql';
import createContactMutation from './graphql/create_contact.mutation.graphql';
import updateContactMutation from './graphql/update_contact.mutation.graphql';

export default {
  components: {
    CrmForm,
  },
  inject: ['groupFullPath', 'groupId'],
  props: {
    isEditMode: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      organizations: [],
    };
  },
  apollo: {
    organizations: {
      query() {
        return getGroupOrganizationsQuery;
      },
      variables() {
        return {
          groupFullPath: this.groupFullPath,
        };
      },
      update(data) {
        return this.extractOrganizations(data);
      },
    },
  },
  computed: {
    contactGraphQLId() {
      if (!this.isEditMode) return null;

      return convertToGraphQLId(TYPENAME_CRM_CONTACT, this.$route.params.id);
    },
    groupGraphQLId() {
      return convertToGraphQLId(TYPENAME_GROUP, this.groupId);
    },
    mutation() {
      if (this.isEditMode) return updateContactMutation;

      return createContactMutation;
    },
    getQuery() {
      return {
        query: getGroupContactsQuery,
        variables: { groupFullPath: this.groupFullPath, ids: [this.contactGraphQLId] },
      };
    },
    title() {
      if (this.isEditMode) return s__('Crm|Edit contact');

      return s__('Crm|New contact');
    },
    successMessage() {
      if (this.isEditMode) return s__('Crm|Contact has been updated.');

      return s__('Crm|Contact has been added.');
    },
    additionalCreateParams() {
      return { groupId: this.groupGraphQLId };
    },
    fields() {
      const fields = [
        { name: 'firstName', label: __('First name'), required: true },
        { name: 'lastName', label: __('Last name'), required: true },
        { name: 'email', label: __('Email'), required: true },
        { name: 'phone', label: __('Phone') },
        {
          name: 'organizationId',
          label: s__('Crm|Organization'),
          values: this.organizationSelectValues,
        },
        { name: 'description', label: __('Description') },
      ];

      if (this.isEditMode)
        fields.push({ name: 'active', label: s__('Crm|Active'), required: true, bool: true });

      return fields;
    },
    organizationSelectValues() {
      const values = this.organizations.map((o) => {
        return { value: o.id, text: o.name };
      });

      values.unshift({ value: null, text: s__('Crm|No organization') });
      return values;
    },
  },
  methods: {
    extractOrganizations(data) {
      const organizations = data?.group?.organizations?.nodes || [];
      return organizations.slice().sort((a, b) => a.name.localeCompare(b.name));
    },
  },
};
</script>

<template>
  <crm-form
    :drawer-open="true"
    :get-query="getQuery"
    get-query-node-path="group.contacts"
    :mutation="mutation"
    :additional-create-params="additionalCreateParams"
    :existing-id="contactGraphQLId"
    :fields="fields"
    :title="title"
    :success-message="successMessage"
  />
</template>
