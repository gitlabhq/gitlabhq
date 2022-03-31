<script>
import { s__, __ } from '~/locale';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import { TYPE_CRM_CONTACT, TYPE_GROUP } from '~/graphql_shared/constants';
import ContactForm from '../../components/form.vue';
import getGroupContactsQuery from './graphql/get_group_contacts.query.graphql';
import createContactMutation from './graphql/create_contact.mutation.graphql';
import updateContactMutation from './graphql/update_contact.mutation.graphql';

export default {
  components: {
    ContactForm,
  },
  inject: ['groupFullPath', 'groupId'],
  props: {
    isEditMode: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    contactGraphQLId() {
      if (!this.isEditMode) return null;

      return convertToGraphQLId(TYPE_CRM_CONTACT, this.$route.params.id);
    },
    groupGraphQLId() {
      return convertToGraphQLId(TYPE_GROUP, this.groupId);
    },
    mutation() {
      if (this.isEditMode) return updateContactMutation;

      return createContactMutation;
    },
    getQuery() {
      return {
        query: getGroupContactsQuery,
        variables: { groupFullPath: this.groupFullPath },
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
  },
  fields: [
    { name: 'firstName', label: __('First name'), required: true },
    { name: 'lastName', label: __('Last name'), required: true },
    { name: 'email', label: __('Email'), required: true },
    { name: 'phone', label: __('Phone') },
    { name: 'description', label: __('Description') },
  ],
};
</script>

<template>
  <contact-form
    :drawer-open="true"
    :get-query="getQuery"
    get-query-node-path="group.contacts"
    :mutation="mutation"
    :additional-create-params="additionalCreateParams"
    :existing-id="contactGraphQLId"
    :fields="$options.fields"
    :title="title"
    :success-message="successMessage"
  />
</template>
