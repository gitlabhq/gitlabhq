<script>
import {
  GlAlert,
  GlButton,
  GlDropdown,
  GlDropdownItem,
  GlEmptyState,
  GlFormGroup,
  GlFormInputGroup,
  GlModal,
  GlModalDirective,
  GlSprintf,
  GlTooltipDirective,
} from '@gitlab/ui';
import { __, s__, n__, sprintf } from '~/locale';
import Api from '~/api';
import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';
import TitleArea from '~/vue_shared/components/registry/title_area.vue';
import ManifestsList from '~/packages_and_registries/dependency_proxy/components/manifests_list.vue';
import { DEPENDENCY_PROXY_DOCS_PATH } from '~/packages_and_registries/settings/group/constants';
import { GRAPHQL_PAGE_SIZE } from '~/packages_and_registries/dependency_proxy/constants';

import getDependencyProxyDetailsQuery from '~/packages_and_registries/dependency_proxy/graphql/queries/get_dependency_proxy_details.query.graphql';

export default {
  components: {
    GlAlert,
    GlButton,
    GlDropdown,
    GlDropdownItem,
    GlEmptyState,
    GlFormGroup,
    GlFormInputGroup,
    GlModal,
    GlSprintf,
    ClipboardButton,
    TitleArea,
    ManifestsList,
  },
  directives: {
    GlModalDirective,
    GlTooltip: GlTooltipDirective,
  },
  inject: ['groupPath', 'groupId', 'noManifestsIllustration', 'canClearCache', 'settingsPath'],
  i18n: {
    proxyImagePrefix: s__('DependencyProxy|Dependency Proxy image prefix'),
    copyImagePrefixText: s__('DependencyProxy|Copy prefix'),
    blobCountAndSize: s__('DependencyProxy|Contains %{count} blobs of images (%{size})'),
    pageTitle: s__('DependencyProxy|Dependency Proxy'),
    noManifestTitle: s__('DependencyProxy|There are no images in the cache'),
    deleteCacheAlertMessageSuccess: s__(
      'DependencyProxy|All items in the cache are scheduled for removal.',
    ),
    clearCache: s__('DependencyProxy|Clear cache'),
    settingsText: s__('DependencyProxy|Configure in settings'),
  },
  confirmClearCacheModal: 'confirm-clear-cache-modal',
  modalButtons: {
    primary: {
      text: s__('DependencyProxy|Clear cache'),
      attributes: { variant: 'danger' },
    },
    secondary: {
      text: __('Cancel'),
    },
  },
  links: {
    DEPENDENCY_PROXY_DOCS_PATH,
  },
  data() {
    return {
      group: {},
      showDeleteCacheAlert: false,
      deleteCacheAlertMessage: '',
    };
  },
  apollo: {
    group: {
      query: getDependencyProxyDetailsQuery,
      variables() {
        return this.queryVariables;
      },
    },
  },
  computed: {
    queryVariables() {
      return { fullPath: this.groupPath, first: GRAPHQL_PAGE_SIZE };
    },
    pageInfo() {
      return this.group.dependencyProxyManifests?.pageInfo;
    },
    manifests() {
      return this.group.dependencyProxyManifests?.nodes;
    },
    modalTitleWithCount() {
      return sprintf(
        n__(
          'Clear %{count} image from cache?',
          'Clear %{count} images from cache?',
          this.group.dependencyProxyBlobCount,
        ),
        {
          count: this.group.dependencyProxyBlobCount,
        },
      );
    },
    modalConfirmationMessageWithCount() {
      return sprintf(
        n__(
          'You are about to clear %{count} image from the cache. Once you confirm, the next time a pipeline runs it must pull an image or tag from Docker Hub. Are you sure?',
          'You are about to clear %{count} images from the cache. Once you confirm, the next time a pipeline runs it must pull an image or tag from Docker Hub. Are you sure?',
          this.group.dependencyProxyBlobCount,
        ),
        {
          count: this.group.dependencyProxyBlobCount,
        },
      );
    },
    showDeleteDropdown() {
      return this.manifests?.length > 0 && this.canClearCache;
    },
    dependencyProxyImagePrefix() {
      return this.group.dependencyProxyImagePrefix;
    },
    showDependencyProxyImagePrefix() {
      return this.dependencyProxyImagePrefix?.length > 0;
    },
  },
  methods: {
    fetchNextPage() {
      this.fetchMore({
        first: GRAPHQL_PAGE_SIZE,
        after: this.pageInfo?.endCursor,
      });
    },
    fetchPreviousPage() {
      this.fetchMore({
        first: null,
        last: GRAPHQL_PAGE_SIZE,
        before: this.pageInfo?.startCursor,
      });
    },
    fetchMore(variables) {
      this.$apollo.queries.group.fetchMore({
        variables: { ...this.queryVariables, ...variables },
        updateQuery(_, { fetchMoreResult }) {
          return fetchMoreResult;
        },
      });
    },
    async submit() {
      try {
        await Api.deleteDependencyProxyCacheList(this.groupId);

        this.deleteCacheAlertMessage = this.$options.i18n.deleteCacheAlertMessageSuccess;
        this.showDeleteCacheAlert = true;
      } catch (err) {
        this.deleteCacheAlertMessage = err;
        this.showDeleteCacheAlert = true;
      }
    },
  },
};
</script>

<template>
  <div>
    <gl-alert
      v-if="showDeleteCacheAlert"
      data-testid="delete-cache-alert"
      @dismiss="showDeleteCacheAlert = false"
    >
      {{ deleteCacheAlertMessage }}
    </gl-alert>
    <title-area :title="$options.i18n.pageTitle">
      <template #right-actions>
        <gl-dropdown
          v-if="showDeleteDropdown"
          icon="ellipsis_v"
          text="More actions"
          :text-sr-only="true"
          category="tertiary"
          no-caret
        >
          <gl-dropdown-item
            v-gl-modal-directive="$options.confirmClearCacheModal"
            variant="danger"
            >{{ $options.i18n.clearCache }}</gl-dropdown-item
          >
        </gl-dropdown>
        <gl-button
          v-if="canClearCache"
          v-gl-tooltip="$options.i18n.settingsText"
          icon="settings"
          data-testid="settings-link"
          :href="settingsPath"
          :aria-label="$options.i18n.settingsText"
        />
      </template>
    </title-area>

    <gl-form-group v-if="showDependencyProxyImagePrefix" :label="$options.i18n.proxyImagePrefix">
      <gl-form-input-group
        readonly
        :value="group.dependencyProxyImagePrefix"
        class="gl-layout-w-limited"
        data-testid="proxy-url"
      >
        <template #append>
          <clipboard-button
            :text="group.dependencyProxyImagePrefix"
            :title="$options.i18n.copyImagePrefixText"
          />
        </template>
      </gl-form-input-group>
      <template #description>
        <span data-qa-selector="dependency_proxy_count" data-testid="proxy-count">
          <gl-sprintf :message="$options.i18n.blobCountAndSize">
            <template #count>{{ group.dependencyProxyBlobCount }}</template>
            <template #size>{{ group.dependencyProxyTotalSize }}</template>
          </gl-sprintf>
        </span>
      </template>
    </gl-form-group>

    <manifests-list
      v-if="manifests && manifests.length"
      :dependency-proxy-image-prefix="dependencyProxyImagePrefix"
      :loading="$apollo.queries.group.loading"
      :manifests="manifests"
      :pagination="pageInfo"
      @prev-page="fetchPreviousPage"
      @next-page="fetchNextPage"
    />

    <gl-empty-state
      v-else
      :svg-path="noManifestsIllustration"
      :title="$options.i18n.noManifestTitle"
    />

    <gl-modal
      :modal-id="$options.confirmClearCacheModal"
      :title="modalTitleWithCount"
      :action-primary="$options.modalButtons.primary"
      :action-secondary="$options.modalButtons.secondary"
      @primary="submit"
    >
      {{ modalConfirmationMessageWithCount }}
    </gl-modal>
  </div>
</template>
