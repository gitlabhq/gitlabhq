<script>
import { GlFilteredSearchSuggestion } from '@gitlab/ui';

import { ITEM_TYPE } from '~/groups/constants';
import { getIdFromGraphQLId, convertToGraphQLId } from '~/graphql_shared/utils';
import createFlash from '~/flash';
import { isPositiveInteger } from '~/lib/utils/number_utils';
import { __ } from '~/locale';
import searchCrmContactsQuery from '../queries/search_crm_contacts.query.graphql';

import { DEFAULT_NONE_ANY } from '../constants';

import BaseToken from './base_token.vue';

export default {
  components: {
    BaseToken,
    GlFilteredSearchSuggestion,
  },
  props: {
    config: {
      type: Object,
      required: true,
    },
    value: {
      type: Object,
      required: true,
    },
    active: {
      type: Boolean,
      required: true,
    },
  },
  data() {
    return {
      contacts: this.config.initialContacts || [],
      loading: false,
    };
  },
  computed: {
    defaultContacts() {
      return this.config.defaultContacts || DEFAULT_NONE_ANY;
    },
    namespace() {
      return this.config.isProject ? ITEM_TYPE.PROJECT : ITEM_TYPE.GROUP;
    },
  },
  methods: {
    getActiveContact(contacts, data) {
      return contacts.find((contact) => {
        return `${this.formatContactId(contact)}` === data;
      });
    },
    getContactName(contact) {
      return `${contact.firstName} ${contact.lastName}`;
    },
    fetchContacts(searchTerm) {
      let searchString = null;
      let searchId = null;
      if (isPositiveInteger(searchTerm)) {
        searchId = this.formatContactGraphQLId(searchTerm);
      } else {
        searchString = searchTerm;
      }

      this.loading = true;

      this.$apollo
        .query({
          query: searchCrmContactsQuery,
          variables: {
            fullPath: this.config.fullPath,
            searchString,
            searchIds: searchId ? [searchId] : null,
            isProject: this.config.isProject,
          },
        })
        .then(({ data }) => {
          this.contacts = this.config.isProject
            ? data[this.namespace]?.group.contacts.nodes
            : data[this.namespace]?.contacts.nodes;
        })
        .catch(() =>
          createFlash({
            message: __('There was a problem fetching CRM contacts.'),
          }),
        )
        .finally(() => {
          this.loading = false;
        });
    },
    formatContactId(contact) {
      return `${getIdFromGraphQLId(contact.id)}`;
    },
    formatContactGraphQLId(id) {
      return convertToGraphQLId('CustomerRelations::Contact', id);
    },
  },
};
</script>

<template>
  <base-token
    :config="config"
    :value="value"
    :active="active"
    :suggestions-loading="loading"
    :suggestions="contacts"
    :get-active-token-value="getActiveContact"
    :default-suggestions="defaultContacts"
    v-bind="$attrs"
    @fetch-suggestions="fetchContacts"
    v-on="$listeners"
  >
    <template #view="{ viewTokenProps: { inputValue, activeTokenValue } }">
      {{ activeTokenValue ? getContactName(activeTokenValue) : inputValue }}
    </template>
    <template #suggestions-list="{ suggestions }">
      <gl-filtered-search-suggestion
        v-for="contact in suggestions"
        :key="formatContactId(contact)"
        :value="formatContactId(contact)"
      >
        <div>
          <div>{{ getContactName(contact) }}</div>
          <div class="gl-font-sm">{{ contact.email }}</div>
        </div>
      </gl-filtered-search-suggestion>
    </template>
  </base-token>
</template>
