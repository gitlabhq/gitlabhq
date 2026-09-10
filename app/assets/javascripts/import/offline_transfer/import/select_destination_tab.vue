<script>
import { GlAlert, GlCollapsibleListbox, GlFormRadio, GlFormGroup } from '@gitlab/ui';
import { DEFAULT_PER_PAGE } from '~/api';
import { s__ } from '~/locale';
import { captureException } from '~/sentry/sentry_browser_wrapper';
import offlineTransferSourceOwnedGroupsQuery from '~/import/offline_transfer/graphql/queries/offline_transfer_source_owned_groups.query.graphql';
import { DESTINATION_TOP_LEVEL, DESTINATION_EXISTING_GROUP } from '../constants';

export default {
  name: 'SelectDestinationTab',
  components: {
    GlAlert,
    GlCollapsibleListbox,
    GlFormRadio,
    GlFormGroup,
  },
  props: {
    destinationSelection: {
      type: Object,
      required: false,
      default: () => ({
        type: DESTINATION_TOP_LEVEL,
        parentGroup: null,
      }),
    },
    validationAttempted: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  emits: ['destination-input'],
  data() {
    return {
      ownedGroups: null,
      hasFetchError: false,
      isFetchingNextPage: false,
    };
  },
  apollo: {
    ownedGroups: {
      query: offlineTransferSourceOwnedGroupsQuery,
      variables() {
        return { first: DEFAULT_PER_PAGE };
      },
      skip() {
        return !this.isDestinationExistingGroup;
      },
      update({ groups }) {
        return groups;
      },
      result({ data }) {
        if (data) this.hasFetchError = false;
      },
      error(error) {
        this.hasFetchError = true;
        captureException(error);
      },
    },
  },
  computed: {
    isDestinationExistingGroup() {
      return this.destinationSelection.type === DESTINATION_EXISTING_GROUP;
    },
    ownedGroupNodes() {
      return this.ownedGroups?.nodes ?? [];
    },
    pageInfo() {
      return this.ownedGroups?.pageInfo ?? null;
    },
    hasGroups() {
      return this.ownedGroupNodes.length > 0;
    },
    groupItems() {
      return this.ownedGroupNodes.map(({ fullPath, fullName }) => ({
        value: fullPath,
        text: fullName,
      }));
    },
    selectedParentPath() {
      return this.destinationSelection.parentGroup?.fullPath ?? null;
    },
    selectedParentName() {
      return (
        this.destinationSelection.parentGroup?.fullName ??
        s__('OfflineTransferImport|Select a group')
      );
    },
    parentGroupMissingError() {
      if (!this.isDestinationExistingGroup || this.destinationSelection.parentGroup) return null;

      return s__('OfflineTransferImport|Select a parent group.');
    },
    parentGroupState() {
      return this.validationAttempted && this.parentGroupMissingError ? false : null;
    },
    isInitialLoading() {
      return this.$apollo.queries.ownedGroups.loading && !this.ownedGroups;
    },
    isEmptyGroupsList() {
      return (
        Boolean(this.ownedGroups) &&
        !this.hasFetchError &&
        !this.isInitialLoading &&
        this.ownedGroupNodes.length === 0
      );
    },
  },
  methods: {
    borderClass(type) {
      return this.destinationSelection.type === type
        ? 'gl-border-[var(--gl-control-border-color-selected-default)]'
        : 'gl-border-default';
    },
    updateDestinationField(field, fieldValue) {
      this.$emit('destination-input', { ...this.destinationSelection, [field]: fieldValue });
    },
    selectParent(fullPath) {
      const parentGroup = this.ownedGroupNodes.find((group) => group.fullPath === fullPath) ?? null;

      this.updateDestinationField('parentGroup', parentGroup);
    },
    onBottomReached() {
      if (this.isFetchingNextPage || !this.pageInfo?.hasNextPage) return;

      this.isFetchingNextPage = true;
      this.$apollo.queries.ownedGroups
        .fetchMore({
          variables: { first: DEFAULT_PER_PAGE, after: this.pageInfo.endCursor },
          updateQuery(previousResult, { fetchMoreResult }) {
            return {
              groups: {
                ...fetchMoreResult.groups,
                nodes: [...previousResult.groups.nodes, ...fetchMoreResult.groups.nodes],
              },
            };
          },
        })
        .catch((error) => {
          this.hasFetchError = true;
          captureException(error);
        })
        .finally(() => {
          this.isFetchingNextPage = false;
        });
    },
    onRetryFetch() {
      this.hasFetchError = false;
      this.$apollo.queries.ownedGroups.refetch().catch(() => {});
    },
    selectDestination(type) {
      const parentGroup =
        type === DESTINATION_TOP_LEVEL ? null : this.destinationSelection.parentGroup;
      this.$emit('destination-input', { ...this.destinationSelection, type, parentGroup });
    },
  },
  DESTINATION_TOP_LEVEL,
  DESTINATION_EXISTING_GROUP,
};
</script>

<template>
  <div class="gl-max-w-2xl">
    <h2 id="destination-heading" class="gl-heading-3 gl-mb-2">
      {{ s__('OfflineTransferImport|Select destination') }}
    </h2>
    <p id="destination-description" class="gl-my-4">
      {{
        s__(
          'OfflineTransferImport|Choose where the imported groups are created on this instance. This choice applies to every group in the package.',
        )
      }}
    </p>

    <div
      role="radiogroup"
      aria-labelledby="destination-heading"
      aria-describedby="destination-description"
      data-testid="destination-radiogroup"
    >
      <div
        class="gl-border gl-mb-4 gl-cursor-pointer gl-rounded-base gl-p-4"
        :class="borderClass($options.DESTINATION_TOP_LEVEL)"
        data-testid="top-level-card"
        @click="selectDestination($options.DESTINATION_TOP_LEVEL)"
      >
        <gl-form-radio
          :checked="destinationSelection.type"
          name="destination"
          :value="$options.DESTINATION_TOP_LEVEL"
          class="gl-mb-0"
          @change="selectDestination($options.DESTINATION_TOP_LEVEL)"
        >
          <p class="gl-mb-0 gl-font-bold">
            {{ s__('OfflineTransferImport|Import all as top-level groups') }}
          </p>
          <template #help>
            {{
              s__(
                'OfflineTransferImport|Each imported group becomes a new top-level group, with no parent.',
              )
            }}
          </template>
        </gl-form-radio>
      </div>

      <div
        class="gl-border gl-cursor-pointer gl-rounded-base gl-p-4"
        :class="borderClass($options.DESTINATION_EXISTING_GROUP)"
        data-testid="existing-group-card"
        @click="selectDestination($options.DESTINATION_EXISTING_GROUP)"
      >
        <gl-form-radio
          :checked="destinationSelection.type"
          name="destination"
          :value="$options.DESTINATION_EXISTING_GROUP"
          class="gl-mb-0"
          @change="selectDestination($options.DESTINATION_EXISTING_GROUP)"
        >
          <p class="gl-mb-0 gl-font-bold">
            {{ s__('OfflineTransferImport|Import all under an existing group') }}
          </p>
          <template #help>
            {{ s__('OfflineTransferImport|All groups are imported as subgroups of one parent.') }}
          </template>
        </gl-form-radio>

        <transition name="fade">
          <div
            v-if="isDestinationExistingGroup"
            class="gl-border-t gl-ml-6 gl-mt-4 gl-cursor-auto gl-border-subtle gl-pt-4"
            @click.stop
          >
            <gl-alert
              v-if="hasFetchError"
              variant="danger"
              :primary-button-text="__('Retry')"
              data-testid="groups-fetch-error"
              @primary-action="onRetryFetch"
            >
              {{ s__('OfflineTransferImport|Could not load your groups.') }}
            </gl-alert>

            <gl-alert v-else-if="isEmptyGroupsList" variant="info" :dismissible="false">
              {{
                s__(
                  'OfflineTransferImport|You do not own any groups. Import the groups as top-level groups instead.',
                )
              }}
            </gl-alert>

            <gl-form-group
              v-else
              :label="s__('OfflineTransferImport|Parent group')"
              label-for="parent-group-listbox"
              class="gl-mb-0"
              :state="parentGroupState"
              :invalid-feedback="parentGroupMissingError"
              data-testid="parent-group-group"
            >
              <gl-collapsible-listbox
                id="parent-group-listbox"
                block
                :items="groupItems"
                :selected="selectedParentPath"
                :toggle-text="selectedParentName"
                :loading="isInitialLoading"
                :state="parentGroupState"
                :infinite-scroll="hasGroups"
                :infinite-scroll-loading="isFetchingNextPage"
                @select="selectParent"
                @bottom-reached="onBottomReached"
              />
            </gl-form-group>
          </div>
        </transition>
      </div>
    </div>
  </div>
</template>
