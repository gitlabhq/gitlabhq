<script>
import { GlIcon, GlLink, GlPopover, GlTooltipDirective } from '@gitlab/ui';
import { __, n__, sprintf } from '~/locale';
import { createAlert } from '~/alert';
import { convertToGraphQLId, getIdFromGraphQLId } from '~/graphql_shared/utils';
import { TYPENAME_ISSUE } from '~/graphql_shared/constants';
import getIssueCrmContactsQuery from '../../queries/get_issue_crm_contacts.query.graphql';
import issueCrmContactsSubscription from '../../queries/issue_crm_contacts.subscription.graphql';

export default {
  components: {
    GlIcon,
    GlLink,
    GlPopover,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    issueId: {
      type: String,
      required: true,
    },
    groupIssuesPath: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      contacts: [],
    };
  },
  apollo: {
    contacts: {
      query: getIssueCrmContactsQuery,
      variables() {
        return this.queryVariables;
      },
      update(data) {
        return data?.issue?.customerRelationsContacts?.nodes;
      },
      error(error) {
        createAlert({
          message: __('Something went wrong trying to load issue contacts.'),
          error,
          captureError: true,
        });
      },
      subscribeToMore: {
        document: issueCrmContactsSubscription,
        variables() {
          return this.queryVariables;
        },
        updateQuery(prev, { subscriptionData }) {
          const draftData = subscriptionData?.data?.issueCrmContactsUpdated;
          if (prev && draftData) return { issue: draftData };
          return prev;
        },
      },
    },
  },
  computed: {
    shouldShowContacts() {
      return this.contacts?.length;
    },
    queryVariables() {
      return { id: convertToGraphQLId(TYPENAME_ISSUE, this.issueId) };
    },
    contactsLabel() {
      return sprintf(n__('%{count} contact', '%{count} contacts', this.contactCount), {
        count: this.contactCount,
      });
    },
    contactCount() {
      return this.contacts?.length || 0;
    },
  },
  methods: {
    shouldShowPopover(contact) {
      return this.popOverData(contact).length > 0;
    },
    divider(index) {
      if (index < this.contactCount - 1) return ',';
      return '';
    },
    popOverData(contact) {
      return [contact.organization?.name, contact.email, contact.phone, contact.description].filter(
        Boolean,
      );
    },
    getIssuesPath(contactId) {
      const id = getIdFromGraphQLId(contactId);
      return `${this.groupIssuesPath}?crm_contact_id=${id}`;
    },
  },
};
</script>

<template>
  <div>
    <div v-gl-tooltip.left.viewport :title="contactsLabel" class="sidebar-collapsed-icon">
      <gl-icon name="users" />
      <span> {{ contactCount }} </span>
    </div>
    <div class="hide-collapsed help-button gl-float-right">
      <gl-link href="https://docs.gitlab.com/ee/user/crm/" target="_blank"
        ><gl-icon name="question-o"
      /></gl-link>
    </div>
    <div class="title hide-collapsed gl-mb-2 gl-line-height-20 gl-font-weight-bold">
      {{ contactsLabel }}
    </div>
    <div class="hide-collapsed gl-display-flex gl-flex-wrap">
      <div
        v-for="(contact, index) in contacts"
        :id="`contact_container_${index}`"
        :key="index"
        class="gl-pr-2"
      >
        <gl-link :id="`contact_${index}`" :href="getIssuesPath(contact.id)"
          >{{ contact.firstName }} {{ contact.lastName }}{{ divider(index) }}</gl-link
        >
        <gl-popover
          v-if="shouldShowPopover(contact)"
          :target="`contact_${index}`"
          :container="`contact_container_${index}`"
          triggers="hover focus"
          placement="top"
        >
          <div v-for="row in popOverData(contact)" :key="row">{{ row }}</div>
        </gl-popover>
      </div>
    </div>
  </div>
</template>
