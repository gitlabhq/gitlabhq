<script>
import { GlIcon, GlLink, GlPopover } from '@gitlab/ui';
import { difference, groupBy, xor } from 'lodash';
import { findWidget } from '~/issues/list/utils';
import { __, n__, s__ } from '~/locale';
import WorkItemSidebarDropdownWidget from '~/work_items/components/shared/work_item_sidebar_dropdown_widget.vue';
import Tracking from '~/tracking';
import getGroupContactsQuery from '~/crm/contacts/components/graphql/get_group_contacts.query.graphql';
import workItemByIidQuery from '~/work_items/graphql/work_item_by_iid.query.graphql';
import updateWorkItemMutation from '../graphql/update_work_item.mutation.graphql';
import updateNewWorkItemMutation from '../graphql/update_new_work_item.mutation.graphql';
import {
  i18n,
  TRACKING_CATEGORY_SHOW,
  I18N_WORK_ITEM_ERROR_FETCHING_CRM_CONTACTS,
  WIDGET_TYPE_CRM_CONTACTS,
} from '../constants';
import { newWorkItemFullPath, newWorkItemId } from '../utils';

export default {
  components: {
    GlIcon,
    GlLink,
    GlPopover,
    WorkItemSidebarDropdownWidget,
  },
  mixins: [Tracking.mixin()],
  props: {
    fullPath: {
      type: String,
      required: true,
    },
    workItemId: {
      type: String,
      required: true,
    },
    workItemIid: {
      type: String,
      required: true,
    },
    workItemType: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      searchTerm: '',
      searchStarted: false,
      updateInProgress: false,
    };
  },
  computed: {
    createFlow() {
      return this.workItemId === newWorkItemId(this.workItemType);
    },
    selectedItems() {
      return this.workItemCrmContacts?.contacts.nodes || [];
    },
    isLoading() {
      return this.$apollo.queries.searchItems.loading;
    },
    selectedItemIds() {
      return this.selectedItems.map(({ id }) => id);
    },
    listItems() {
      const contacts = this.searchItems || [];
      const organizations = this.groupByOrganization(contacts, true);
      return organizations.map(([key, values]) => {
        return {
          text: key,
          options: values.map((contact) => {
            return { value: contact.id, text: `${contact.firstName} ${contact.lastName}` };
          }),
        };
      });
    },
    tracking() {
      return {
        category: TRACKING_CATEGORY_SHOW,
        label: 'item_contact',
        property: `type_${this.workItemType}`,
      };
    },
    selectedOrganizations() {
      return this.groupByOrganization(this.selectedItems, false);
    },
    workItemCrmContacts() {
      return findWidget(WIDGET_TYPE_CRM_CONTACTS, this.workItem);
    },
    workItemFullPath() {
      return this.createFlow
        ? newWorkItemFullPath(this.fullPath, this.workItemType)
        : this.fullPath;
    },
    canUpdate() {
      return this.workItem?.userPermissions?.updateWorkItem;
    },
    dropdownLabelText() {
      return n__('%d contact', '%d contacts', this.selectedItemIds.length);
    },
  },
  apollo: {
    searchItems: {
      query: getGroupContactsQuery,
      variables() {
        return {
          groupFullPath: this.fullPath.split('/')[0],
          searchTerm: this.searchTerm,
        };
      },
      skip() {
        return !this.searchStarted;
      },
      update(data) {
        return data.group?.contacts?.nodes;
      },
      error() {
        this.$emit('error', I18N_WORK_ITEM_ERROR_FETCHING_CRM_CONTACTS);
      },
    },
    workItem: {
      query: workItemByIidQuery,
      variables() {
        return {
          fullPath: this.workItemFullPath,
          iid: this.workItemIid,
        };
      },
      update(data) {
        return data?.workspace?.workItem ?? {};
      },
      skip() {
        return !this.workItemIid;
      },
    },
  },
  methods: {
    groupByOrganization(unsortedContacts, separateSelectedContacts) {
      // Sort the contacts first
      const contacts = [...unsortedContacts].sort((a, b) => {
        if (a.firstName !== b.firstName) {
          return a.firstName.localeCompare(b.firstName);
        }
        return a.lastName.localeCompare(b.lastName);
      });

      let groups = [];
      let remainingContacts;
      // Group the selected contacts first
      if (separateSelectedContacts && this.selectedItems.length) {
        remainingContacts = contacts.filter(
          (contact) => !this.selectedItemIds.includes(contact.id),
        );
        groups.push([
          __('Selected'),
          contacts.filter((contact) => this.selectedItemIds.includes(contact.id)),
        ]);
      } else {
        remainingContacts = contacts;
      }

      const orphanContacts = remainingContacts.filter(({ organization }) => !organization);
      // Display each organization and their contacts next
      remainingContacts = remainingContacts.filter(({ organization }) => organization);
      const organizationGroups = Object.entries(groupBy(remainingContacts, 'organization.name'));
      organizationGroups.sort((a, b) => a[0].localeCompare(b[0]));
      groups = groups.concat(organizationGroups);

      // Then finally display contacts without an organization
      if (orphanContacts.length) {
        groups.push([s__('Crm|No organization'), orphanContacts]);
      }
      return groups;
    },
    search(searchTerm = '') {
      this.searchTerm = searchTerm;
      this.searchStarted = true;
    },
    async updateItems(newSelectedItemIds) {
      this.updateInProgress = true;
      let newSelectedItems;

      const differingItems = xor(newSelectedItemIds, this.selectedItemIds);

      if (differingItems === 0) return;
      if (newSelectedItemIds.length === 0) {
        newSelectedItems = [];
      } else {
        const removeIds = difference(this.selectedItemIds, newSelectedItemIds);
        if (removeIds.length > 0) {
          newSelectedItems = this.selectedItems.filter(({ id }) => !removeIds.includes(id));
        }

        const addIds = difference(newSelectedItemIds, this.selectedItemIds);
        if (addIds.length > 0) {
          newSelectedItems = [
            ...this.selectedItems,
            ...this.searchItems.filter(({ id }) => addIds.includes(id)),
          ];
        }
      }

      if (this.createFlow) {
        this.$apollo.mutate({
          mutation: updateNewWorkItemMutation,
          variables: {
            input: {
              workItemType: this.workItemType,
              fullPath: this.fullPath,
              crmContacts: newSelectedItems,
            },
          },
        });

        this.updateInProgress = false;
        return;
      }

      try {
        const {
          data: {
            workItemUpdate: { errors },
          },
        } = await this.$apollo.mutate({
          mutation: updateWorkItemMutation,
          variables: {
            input: {
              id: this.workItemId,
              crmContactsWidget: {
                contactIds: newSelectedItemIds,
              },
            },
          },
        });

        if (errors.length > 0) {
          throw new Error(errors[0].message);
        }

        this.track('updated_contacts');
      } catch {
        this.$emit('error', i18n.updateError);
      } finally {
        this.searchTerm = '';
        this.updateInProgress = false;
      }
    },
  },
};
</script>

<template>
  <work-item-sidebar-dropdown-widget
    :dropdown-label="s__('Crm|Contacts')"
    :can-update="canUpdate"
    dropdown-name="crm-contacts"
    :loading="isLoading"
    :list-items="listItems"
    :item-value="selectedItemIds"
    :update-in-progress="updateInProgress"
    :toggle-dropdown-text="dropdownLabelText"
    :header-text="s__('Crm|Select contacts')"
    multi-select
    clear-search-on-item-select
    data-testid="work-item-crm-contacts"
    @dropdownShown="search"
    @searchStarted="search"
    @updateValue="updateItems"
  >
    <template #readonly>
      <div class="gl-gap-2 gl-mt-1">
        <div
          v-for="[organizationName, contacts] in selectedOrganizations"
          :key="organizationName"
          data-testid="organization"
        >
          <div class="gl-text-secondary gl-mt-3">{{ organizationName }}</div>
          <div
            v-for="contact in contacts"
            :id="`contact_container_${contact.id}`"
            :key="contact.id"
            data-testid="contact"
          >
            <gl-link :id="`contact_${contact.id}`" class="gl-text-inherit">
              {{ contact.firstName }} {{ contact.lastName }}
            </gl-link>
            <gl-popover
              :target="`contact_${contact.id}`"
              :container="`contact_container_${contact.id}`"
              triggers="hover focus"
              placement="top"
            >
              <div>{{ contact.firstName }} {{ contact.lastName }}</div>
              <div class="gl-text-secondary">
                <div>{{ contact.description }}</div>
                <div v-if="contact.email">
                  <gl-icon name="mail" class="gl-mr-2" />{{ contact.email }}
                </div>
                <div v-if="contact.phone">
                  <gl-icon name="mobile" class="gl-mr-2" />{{ contact.phone }}
                </div>
                <div v-if="organizationName !== s__('Crm|No organization')">
                  <gl-icon name="building" class="gl-mr-2" />{{ organizationName }}
                </div>
              </div>
            </gl-popover>
          </div>
        </div>
      </div>
    </template>
  </work-item-sidebar-dropdown-widget>
</template>
