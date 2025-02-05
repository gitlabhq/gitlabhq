<script>
import { GlButton, GlLoadingIcon, GlEmptyState, GlKeysetPagination } from '@gitlab/ui';
import { differenceBy } from 'lodash';
import { s__, __, sprintf } from '~/locale';
import { createAlert } from '~/alert';
import { fetchPolicies } from '~/lib/graphql';
import { TYPENAME_PROJECT, TYPENAME_GROUP } from '~/graphql_shared/constants';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import { capitalizeFirstCharacter } from '~/lib/utils/text_utility';
import globalToast from '~/vue_shared/plugins/global_toast';
import fetchExclusions from '../graphql/queries/beyond_identity_exclusions.query.graphql';
import createExclusion from '../graphql/mutations/create_beyond_identity_exclusion.mutation.graphql';
import deleteExclusion from '../graphql/mutations/delete_beyond_identity_exclusion.mutation.graphql';
import {
  BEYOND_IDENTITY_INTEGRATION_NAME,
  PROJECT_TYPE,
  GROUP_TYPE,
  DEFAULT_CURSOR,
} from '../constants';
import ExclusionsTabs from './exclusions_tabs.vue';
import ExclusionsListItem from './exclusions_list_item.vue';
import AddExclusionsDrawer from './add_exclusions_drawer.vue';
import ConfirmRemovalModal from './remove_exclusion_confirmation_modal.vue';

export default {
  name: 'ExclusionsList',
  components: {
    GlButton,
    GlLoadingIcon,
    GlEmptyState,
    ExclusionsTabs,
    ExclusionsListItem,
    GlKeysetPagination,
    AddExclusionsDrawer,
    ConfirmRemovalModal,
  },
  data() {
    return {
      isDrawerOpen: false,
      isConfirmRemovalModalOpen: false,
      exclusions: [],
      exclusionToRemove: null,
      pageInfo: {},
      cursor: DEFAULT_CURSOR,
    };
  },
  apollo: {
    exclusions: {
      query: fetchExclusions,
      fetchPolicy: fetchPolicies.CACHE_AND_NETWORK,
      variables() {
        return this.cursor;
      },
      update({ integrationExclusions }) {
        this.pageInfo = integrationExclusions?.pageInfo || {};
        return integrationExclusions?.nodes || [];
      },
      error() {
        this.handleError(this.$options.i18n.errorFetch);
      },
    },
  },
  computed: {
    formattedExclusions() {
      return this.exclusions.map((exclusion) => {
        const type = exclusion.project ? PROJECT_TYPE : GROUP_TYPE;
        return {
          ...exclusion[type],
          icon: type,
          type,
        };
      });
    },
    showPagination() {
      return this.pageInfo?.hasPreviousPage || this.pageInfo?.hasNextPage;
    },
    isLoading() {
      return this.$apollo.queries.exclusions.loading;
    },
    isEmpty() {
      return !this.isLoading && !this.exclusions.length;
    },
  },
  methods: {
    async handleAddExclusions(exclusions) {
      const uniqueList = differenceBy(exclusions, this.exclusions, (v) => [v.id, v.type].join());

      const { data } = await this.$apollo.mutate({
        mutation: createExclusion,
        variables: {
          input: {
            projectIds: this.extractProjectIds(uniqueList),
            groupIds: this.extractGroupIds(uniqueList),
            integrationName: BEYOND_IDENTITY_INTEGRATION_NAME,
          },
        },
      });

      this.isDrawerOpen = false;

      if (data?.integrationExclusionCreate?.errors?.length) {
        this.handleError(this.$options.i18n.errorCreate);
        return;
      }

      if (this.pageInfo.hasPreviousPage) {
        this.resetPagination();
      } else {
        this.$apollo.queries.exclusions.refetch();
      }
    },
    extractProjectIds(exclusions) {
      return exclusions
        .filter((exclusion) => exclusion.type === PROJECT_TYPE)
        .map((exclusion) => convertToGraphQLId(TYPENAME_PROJECT, exclusion.id));
    },
    extractGroupIds(exclusions) {
      return exclusions
        .filter((exclusion) => exclusion.type === GROUP_TYPE)
        .map((exclusion) => convertToGraphQLId(TYPENAME_GROUP, exclusion.id));
    },
    nextPage(item) {
      this.cursor = { after: item, last: null, before: null };
    },
    prevPage(item) {
      this.cursor = { first: null, after: null, before: item };
    },
    resetPagination() {
      this.cursor = DEFAULT_CURSOR;
    },
    handleError(message) {
      createAlert({ message });
    },
    showRemoveModal(exclusion) {
      this.exclusionToRemove = exclusion;
      this.isConfirmRemovalModalOpen = true;
    },
    hideRemoveModal() {
      this.isConfirmRemovalModalOpen = false;
    },
    async confirmRemoveExclusion() {
      const { exclusionToRemove } = this;

      const { data } = await this.$apollo.mutate({
        mutation: deleteExclusion,
        variables: {
          input: {
            projectIds: this.extractProjectIds([exclusionToRemove]),
            groupIds: this.extractGroupIds([exclusionToRemove]),
            integrationName: BEYOND_IDENTITY_INTEGRATION_NAME,
          },
        },
      });

      if (data?.integrationExclusionDelete?.errors?.length) {
        this.handleError(this.$options.i18n.errorDelete);
        return;
      }

      if (this.exclusions.length === 1 && this.pageInfo.hasPreviousPage) {
        this.prevPage(this.pageInfo.startCursor);
      } else {
        this.$apollo.queries.exclusions.refetch();
      }

      const type = capitalizeFirstCharacter(exclusionToRemove.type);

      globalToast(sprintf(this.$options.i18n.exclusionRemoved, { type }), {
        action: {
          text: __('Undo'),
          onClick: (_, toast) => {
            this.handleAddExclusions([exclusionToRemove]);
            toast.hide();
          },
        },
      });
    },
    toggleDrawer() {
      this.isDrawerOpen = !this.isDrawerOpen;
    },
  },
  i18n: {
    errorCreate: s__('Integrations|Failed to add the exclusion. Try adding it again.'),
    errorDelete: s__('Integrations|Failed to remove the exclusion. Try removing it again.'),
    errorFetch: s__('Integrations|Failed to fetch the exclusions. Try refreshing the page.'),
    exclusionRemoved: s__('Integrations|%{type} exclusion removed'),
    emptyText: s__('Integrations|There are no exclusions'),
    addExclusions: s__('Integrations|Add exclusions'),
    helpText: s__(
      'Integrations|Groups and projects in this list no longer require commits to be signed.',
    ),
  },
};
</script>

<template>
  <div>
    <exclusions-tabs />

    <div class="gl-border-b gl-flex gl-items-center gl-justify-between gl-bg-subtle gl-p-4 gl-py-5">
      <span>{{ $options.i18n.helpText }}</span>
      <gl-button variant="confirm" data-testid="add-exclusions-btn" @click="isDrawerOpen = true">{{
        $options.i18n.addExclusions
      }}</gl-button>
    </div>

    <gl-empty-state v-if="isEmpty" :title="$options.i18n.emptyText" />

    <exclusions-list-item
      v-for="(exclusion, index) in formattedExclusions"
      v-else
      :key="index"
      :exclusion="exclusion"
      @remove="() => showRemoveModal(exclusion)"
    />

    <gl-loading-icon v-if="isLoading" size="lg" class="gl-my-5" />

    <div v-else class="gl-mt-5 gl-flex gl-justify-center">
      <gl-keyset-pagination
        v-if="showPagination"
        v-bind="pageInfo"
        @prev="prevPage"
        @next="nextPage"
      />
    </div>

    <add-exclusions-drawer
      :is-open="isDrawerOpen"
      @close="isDrawerOpen = false"
      @add="handleAddExclusions"
    />

    <confirm-removal-modal
      v-if="exclusionToRemove && isConfirmRemovalModalOpen"
      :visible="isConfirmRemovalModalOpen"
      :name="exclusionToRemove.name"
      :type="exclusionToRemove.type"
      @primary="confirmRemoveExclusion"
      @hide="hideRemoveModal"
    />
  </div>
</template>
