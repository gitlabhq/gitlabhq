<script>
import {
  GlAvatarLabeled,
  GlBadge,
  GlButton,
  GlKeysetPagination,
  GlLink,
  GlLoadingIcon,
  GlTable,
  GlTooltipDirective,
} from '@gitlab/ui';
import { createAlert } from '~/alert';
import { __, s__ } from '~/locale';
import { fetchPolicies } from '~/lib/graphql';
import { getFirstPropertyValue } from '~/lib/utils/common_utils';
import { localeDateFormat } from '~/lib/utils/datetime/locale_dateformat';
import { DEFAULT_PAGE_SIZE } from '~/members/constants';
import { placeholderUserBadges } from '~/import_entities/import_groups/constants';
import reassignedSourceUsersQuery from '../graphql/reassigned_source_users.query.graphql';
import revokeSourceUserReassignmentMutation from '../graphql/revoke_source_user_reassignment.mutation.graphql';
import RevokeReassignmentModal from './revoke_reassignment_modal.vue';

export default {
  name: 'ReassignedSourceUsers',
  components: {
    GlAvatarLabeled,
    GlBadge,
    GlButton,
    GlKeysetPagination,
    GlLink,
    GlLoadingIcon,
    GlTable,
    RevokeReassignmentModal,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  data() {
    return {
      sourceUsers: null,
      cursor: {
        before: null,
        after: null,
      },
      sourceUserToRevoke: null,
      revokingId: null,
    };
  },
  apollo: {
    sourceUsers: {
      query: reassignedSourceUsersQuery,
      variables() {
        return {
          ...this.cursor,
          [this.cursor.before ? 'last' : 'first']: DEFAULT_PAGE_SIZE,
        };
      },
      fetchPolicy: fetchPolicies.CACHE_FIRST,
      update(data) {
        return data.currentUser?.importSourceUsers;
      },
      error() {
        createAlert({
          message: s__('UserMapping|Reassigned contributions could not be fetched.'),
        });
      },
    },
  },
  computed: {
    isLoading() {
      return this.$apollo.queries.sourceUsers.loading;
    },
    nodes() {
      return this.sourceUsers?.nodes || [];
    },
    pageInfo() {
      return this.sourceUsers?.pageInfo || {};
    },
  },
  methods: {
    statusBadge(item) {
      return placeholderUserBadges[item.status];
    },
    formatDate(dateString) {
      return localeDateFormat.asDateTime.format(new Date(dateString));
    },
    onRevokeClick(item) {
      this.sourceUserToRevoke = item;
    },
    onModalHidden() {
      this.sourceUserToRevoke = null;
    },
    onRevokeConfirm() {
      const sourceUser = this.sourceUserToRevoke;
      this.revokingId = sourceUser.id;

      this.$apollo
        .mutate({
          mutation: revokeSourceUserReassignmentMutation,
          variables: {
            id: sourceUser.id,
          },
          refetchQueries: [reassignedSourceUsersQuery],
        })
        .then(({ data }) => {
          const { errors } = getFirstPropertyValue(data);
          if (errors?.length) {
            createAlert({ message: errors.join(' ') });
          }
        })
        .catch(() => {
          createAlert({
            message: s__('UserMapping|Reassignment could not be revoked.'),
          });
        })
        .finally(() => {
          this.revokingId = null;
        });
    },
    onPrevPage() {
      this.cursor = {
        before: this.pageInfo.startCursor,
        after: null,
      };
    },
    onNextPage() {
      this.cursor = {
        after: this.pageInfo.endCursor,
        before: null,
      };
    },
  },
  fields: [
    {
      key: 'user',
      label: s__('UserMapping|Placeholder user'),
    },
    {
      key: 'source',
      label: s__('BulkImport|Source'),
    },
    {
      key: 'namespace',
      label: s__('UserMapping|Imported to'),
    },
    {
      key: 'createdAt',
      label: __('Created at'),
    },
    {
      key: 'status',
      label: s__('UserMapping|Reassignment status'),
    },
    {
      key: 'actions',
      label: '',
    },
  ],
};
</script>

<template>
  <div>
    <gl-table :items="nodes" :fields="$options.fields" :busy="isLoading" show-empty stacked="md">
      <template #table-busy>
        <gl-loading-icon size="lg" class="gl-my-5" />
      </template>

      <template #empty>
        <p class="gl-my-5 gl-text-center gl-text-subtle">
          {{ s__('UserMapping|You have no reassigned contributions.') }}
        </p>
      </template>

      <template #cell(user)="{ item }">
        <gl-avatar-labeled
          v-if="item.placeholderUser"
          :size="32"
          :src="item.placeholderUser.avatarUrl"
          :label="item.placeholderUser.name"
          :sub-label="`@${item.placeholderUser.username}`"
        />
        <span v-else>{{ s__('UserMapping|Placeholder deleted') }}</span>
      </template>

      <template #cell(source)="{ item }">
        <p class="gl-mb-2">{{ item.sourceHostname }}</p>
        <p class="gl-mb-2">{{ item.sourceName }}</p>
        <p v-if="item.sourceUsername" class="gl-mb-2">@{{ item.sourceUsername }}</p>
        <span v-else class="gl-font-subtle gl-italic"
          >{{ s__('UserMapping|User ID') }}: {{ item.sourceUserIdentifier }}</span
        >
      </template>

      <template #cell(namespace)="{ item }">
        <gl-link v-if="item.namespace" :href="item.namespace.webPath">{{
          item.namespace.fullPath
        }}</gl-link>
      </template>

      <template #cell(createdAt)="{ item }">
        <span>{{ formatDate(item.createdAt) }}</span>
      </template>

      <template #cell(status)="{ item }">
        <gl-badge
          v-if="statusBadge(item)"
          v-gl-tooltip="statusBadge(item).tooltip"
          :variant="statusBadge(item).variant"
          data-testid="reassignment-status"
          tabindex="0"
          >{{ statusBadge(item).text }}</gl-badge
        >
      </template>

      <template #cell(actions)="{ item }">
        <gl-button
          category="secondary"
          variant="danger"
          size="small"
          :loading="item.id === revokingId"
          data-testid="revoke-button"
          @click="onRevokeClick(item)"
          >{{ s__('UserMapping|Revoke') }}</gl-button
        >
      </template>
    </gl-table>

    <div v-if="pageInfo.hasNextPage || pageInfo.hasPreviousPage" class="gl-mt-5 gl-text-center">
      <gl-keyset-pagination v-bind="pageInfo" @prev="onPrevPage" @next="onNextPage" />
    </div>

    <revoke-reassignment-modal
      :visible="Boolean(sourceUserToRevoke)"
      :source-user="sourceUserToRevoke"
      @primary="onRevokeConfirm"
      @hidden="onModalHidden"
    />
  </div>
</template>
