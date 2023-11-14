<script>
import { s__, __ } from '~/locale';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import { TYPENAME_CRM_ORGANIZATION, TYPENAME_GROUP } from '~/graphql_shared/constants';
import CrmForm from '../../components/crm_form.vue';
import getGroupOrganizationsQuery from './graphql/get_group_organizations.query.graphql';
import createCustomerRelationsOrganizationMutation from './graphql/create_customer_relations_organization.mutation.graphql';
import updateCustomerRelationsOrganizationMutation from './graphql/update_customer_relations_organization.mutation.graphql';

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
  computed: {
    organizationGraphQLId() {
      if (!this.isEditMode) return null;

      return convertToGraphQLId(TYPENAME_CRM_ORGANIZATION, this.$route.params.id);
    },
    groupGraphQLId() {
      return convertToGraphQLId(TYPENAME_GROUP, this.groupId);
    },
    mutation() {
      if (this.isEditMode) return updateCustomerRelationsOrganizationMutation;

      return createCustomerRelationsOrganizationMutation;
    },
    getQuery() {
      return {
        query: getGroupOrganizationsQuery,
        variables: { groupFullPath: this.groupFullPath, ids: [this.organizationGraphQLId] },
      };
    },
    title() {
      if (this.isEditMode) return s__('Crm|Edit organization');

      return s__('Crm|New organization');
    },
    successMessage() {
      if (this.isEditMode) return s__('Crm|Organization has been updated.');

      return s__('Crm|Organization has been added.');
    },
    additionalCreateParams() {
      return { groupId: this.groupGraphQLId };
    },
    fields() {
      const fields = [
        { name: 'name', label: __('Name'), required: true },
        {
          name: 'defaultRate',
          label: s__('Crm|Default rate'),
          input: { type: 'number', step: '0.01' },
        },
        { name: 'description', label: __('Description') },
      ];

      if (this.isEditMode)
        fields.push({ name: 'active', label: s__('Crm|Active'), required: true, bool: true });

      return fields;
    },
  },
};
</script>

<template>
  <crm-form
    :drawer-open="true"
    :get-query="getQuery"
    get-query-node-path="group.organizations"
    :mutation="mutation"
    :additional-create-params="additionalCreateParams"
    :existing-id="organizationGraphQLId"
    :fields="fields"
    :title="title"
    :success-message="successMessage"
  />
</template>
