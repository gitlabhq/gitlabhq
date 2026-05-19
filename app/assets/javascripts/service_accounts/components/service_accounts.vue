<script>
import {
  GlTabs,
  GlTab,
  GlBadge,
  GlTable,
  GlPagination,
  GlDisclosureDropdown,
  GlSprintf,
  GlLink,
  GlButton,
} from '@gitlab/ui';
import { mapActions, mapState } from 'pinia';
import { s__, sprintf } from '~/locale';

import PageHeading from '~/vue_shared/components/page_heading.vue';

import { useServiceAccounts } from '../stores/service_accounts';

import DeleteServiceAccountModal from './delete_service_account_modal.vue';
import CreateEditServiceAccountModal from './create_edit_service_account_modal.vue';

export default {
  name: 'ServiceAccounts',
  components: {
    GlTabs,
    GlTab,
    GlBadge,
    GlTable,
    GlSprintf,
    GlLink,
    GlPagination,
    GlButton,
    GlDisclosureDropdown,
    PageHeading,
    DeleteServiceAccountModal,
    CreateEditServiceAccountModal,
  },
  inject: [
    'serviceAccountsEnabled',
    'serviceAccountsPath',
    'serviceAccountsEditPath',
    'serviceAccountsDeletePath',
    'serviceAccountsDocsPath',
  ],
  computed: {
    ...mapState(useServiceAccounts, [
      'serviceAccounts',
      'serviceAccount',
      'serviceAccountCount',
      'busy',
      'deleteType',
      'createEditType',
      'page',
      'perPage',
    ]),
  },
  created() {
    if (this.serviceAccountsEnabled) {
      this.fetchServiceAccounts(this.serviceAccountsPath, {
        page: this.page,
      });
    }
  },
  methods: {
    ...mapActions(useServiceAccounts, [
      'fetchServiceAccounts',
      'deleteUser',
      'createServiceAccount',
      'editServiceAccount',
      'setDeleteType',
      'setServiceAccount',
      'setCreateEditType',
      'clearAlert',
    ]),
    addServiceAccount() {
      this.clearAlert();
      this.setServiceAccount(null);
      this.setCreateEditType('create');
    },
    deleteAccount() {
      this.deleteUser(this.serviceAccountsDeletePath);
    },
    async createEditAccount(values) {
      if (this.createEditType === 'create') {
        await this.createServiceAccount(this.serviceAccountsPath, values);
      } else {
        await this.editServiceAccount(this.serviceAccountsEditPath, values);
      }
    },
    routeToAccessTokensManagement(serviceAccountId) {
      this.$router.push({
        name: 'access_tokens',
        params: { id: serviceAccountId },
        replace: true,
      });
    },
    showEmail(serviceAccount) {
      return Boolean(serviceAccount.email) || Boolean(serviceAccount.unconfirmed_email);
    },
    email(addresses) {
      if (addresses.unconfirmed_email) {
        return sprintf(s__('ServiceAccounts|%{email} - unconfirmed'), {
          email: addresses.unconfirmed_email,
        });
      }
      // If server generated placeholder email ignore it - magic string :-(
      if (addresses.email?.includes('@noreply.')) {
        return '';
      }
      return addresses.email;
    },
    pageServiceAccounts(page) {
      this.fetchServiceAccounts(this.serviceAccountsPath, { page });
    },
    optionsItems(serviceAccount) {
      return [
        {
          text: s__('ServiceAccounts|Manage access tokens'),
          action: () => {
            this.clearAlert();
            this.routeToAccessTokensManagement(serviceAccount.id);
          },
        },
        {
          text: s__('ServiceAccounts|Edit'),
          action: () => {
            this.clearAlert();
            this.setServiceAccount(serviceAccount);
            this.setCreateEditType('edit');
          },
        },
        {
          text: s__('ServiceAccounts|Delete account'),
          action: () => {
            this.clearAlert();
            this.setServiceAccount(serviceAccount);
            this.setDeleteType('soft');
          },
          variant: 'danger',
        },
        {
          text: s__('ServiceAccounts|Delete account and contributions'),
          action: () => {
            this.clearAlert();
            this.setServiceAccount(serviceAccount);
            this.setDeleteType('hard');
          },
          variant: 'danger',
        },
      ];
    },
  },
  fields: [
    {
      key: 'name',
      label: s__('ServiceAccounts|Name'),
      thAttr: { 'data-testid': 'header-name' },
      thClass: '!gl-border-t-0',
    },
    {
      key: 'options',
      label: '',
      tdClass: 'gl-text-end',
      tdAttr: { 'data-testid': 'cell-options' },
      thClass: '!gl-border-t-0',
    },
  ],
  i18n: {
    title: s__('ServiceAccounts|Service accounts'),
  },
};
</script>

<template>
  <div>
    <page-heading :heading="$options.i18n.title">
      <template #description>
        <gl-sprintf
          :message="
            s__(
              'ServiceAccounts|Service accounts are non-human accounts that allow interactions between software applications, systems, or services. %{learnMore}',
            )
          "
        >
          <template #learnMore>
            <gl-link :href="serviceAccountsDocsPath">{{ __('Learn more') }}</gl-link>
          </template>
        </gl-sprintf>
      </template>

      <template #actions>
        <gl-button v-if="serviceAccountsEnabled" variant="confirm" @click="addServiceAccount">
          {{ s__('ServiceAccounts|Add service account') }}
        </gl-button>
      </template>
    </page-heading>

    <gl-tabs content-class="gl-pt-0">
      <gl-tab>
        <template #title>
          <span>{{ $options.i18n.title }}</span>
          <gl-badge class="gl-tab-counter-badge">{{ serviceAccountCount }}</gl-badge>
        </template>

        <gl-table
          :items="serviceAccounts"
          :fields="$options.fields"
          :empty-text="s__('ServiceAccounts|No service accounts')"
          show-empty
          :per-page="perPage"
          :busy="busy"
        >
          <template #cell(name)="{ item }">
            <div class="gl-font-bold" data-testid="service-account-name">{{ item.name }}</div>
            <div data-testid="service-account-username">@{{ item.username }}</div>
            <div v-if="showEmail(item)" data-testid="service-account-email">
              {{ email({ email: item.email, unconfirmed_email: item.unconfirmed_email }) }}
            </div>
          </template>

          <template #cell(options)="{ item }">
            <gl-disclosure-dropdown
              icon="ellipsis_v"
              :no-caret="true"
              category="tertiary"
              :fluid-width="true"
              :items="optionsItems(item)"
            />
          </template>
        </gl-table>

        <gl-pagination
          :value="page"
          :per-page="perPage"
          :total-items="serviceAccountCount"
          align="center"
          @input="pageServiceAccounts"
        />
      </gl-tab>
    </gl-tabs>

    <delete-service-account-modal
      v-if="deleteType"
      :delete-type="deleteType"
      :name="serviceAccount.name"
      @cancel="setDeleteType(null)"
      @submit="deleteAccount"
    />

    <create-edit-service-account-modal
      v-if="createEditType"
      :service-account-action-type="createEditType"
      :service-account="serviceAccount"
      @cancel="setCreateEditType(null)"
      @submit="createEditAccount"
    />
  </div>
</template>
