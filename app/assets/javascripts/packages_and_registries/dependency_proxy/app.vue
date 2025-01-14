<script>
import {
  GlAlert,
  GlButton,
  GlDisclosureDropdown,
  GlDisclosureDropdownItem,
  GlFormGroup,
  GlFormInputGroup,
  GlSkeletonLoader,
  GlModal,
  GlModalDirective,
  GlSprintf,
  GlTooltipDirective,
} from '@gitlab/ui';
import { __, s__, n__, sprintf } from '~/locale';
import { deleteDependencyProxyCacheList } from '~/api/packages_api';
import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';
import TitleArea from '~/vue_shared/components/registry/title_area.vue';
import ManifestsList from '~/packages_and_registries/dependency_proxy/components/manifests_list.vue';
import { GRAPHQL_PAGE_SIZE } from '~/packages_and_registries/dependency_proxy/constants';
import { getPageParams } from '~/packages_and_registries/dependency_proxy/utils';

import getDependencyProxyDetailsQuery from '~/packages_and_registries/dependency_proxy/graphql/queries/get_dependency_proxy_details.query.graphql';

export default {
  components: {
    GlAlert,
    GlButton,
    GlDisclosureDropdown,
    GlDisclosureDropdownItem,
    GlSkeletonLoader,
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
  inject: ['groupPath', 'groupId', 'canClearCache', 'settingsPath'],
  i18n: {
    proxyImagePrefix: s__('DependencyProxy|Dependency Proxy image prefix'),
    copyImagePrefixText: s__('DependencyProxy|Copy prefix'),
    blobCountAndSize: s__('DependencyProxy|Contains %{count} blobs of images (%{size})'),
    pageTitle: s__('DependencyProxy|Dependency Proxy'),
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
      return { fullPath: this.groupPath, first: GRAPHQL_PAGE_SIZE, ...this.pageParams };
    },
    pageInfo() {
      return this.group.dependencyProxyManifests?.pageInfo;
    },
    pageParams() {
      const { before, after } = this.$route.query;
      return getPageParams({ before, after });
    },
    manifests() {
      return this.group.dependencyProxyManifests?.nodes ?? [];
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
      this.$router.push({ query: { after: this.pageInfo?.endCursor } });
    },
    fetchPreviousPage() {
      this.$router.push({ query: { before: this.pageInfo?.startCursor } });
    },
    async submit() {
      try {
        await deleteDependencyProxyCacheList(this.groupId);

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
    <gl-alert v-if="showDeleteCacheAlert" @dismiss="showDeleteCacheAlert = false">
      {{ deleteCacheAlertMessage }}
    </gl-alert>
    <title-area :title="$options.i18n.pageTitle">
      <template #right-actions>
        <gl-disclosure-dropdown
          v-if="showDeleteDropdown"
          icon="ellipsis_v"
          :toggle-text="__('More actions')"
          :text-sr-only="true"
          category="tertiary"
          placement="bottom-end"
          no-caret
        >
          <gl-disclosure-dropdown-item v-gl-modal-directive="$options.confirmClearCacheModal">
            <template #list-item>
              <span class="gl-text-red-500">
                {{ $options.i18n.clearCache }}
              </span>
            </template>
          </gl-disclosure-dropdown-item>
        </gl-disclosure-dropdown>
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

    <gl-form-group
      v-if="showDependencyProxyImagePrefix"
      :label="$options.i18n.proxyImagePrefix"
      label-for="proxy-url"
    >
      <gl-form-input-group
        id="proxy-url"
        readonly
        :value="dependencyProxyImagePrefix"
        select-on-click
        class="gl-max-w-limited"
        data-testid="proxy-url"
      >
        <template #append>
          <clipboard-button
            :text="dependencyProxyImagePrefix"
            :title="$options.i18n.copyImagePrefixText"
          />
        </template>
      </gl-form-input-group>
      <template #description>
        <span data-testid="proxy-count">
          <gl-sprintf :message="$options.i18n.blobCountAndSize">
            <template #count>{{ group.dependencyProxyBlobCount }}</template>
            <template #size>{{ group.dependencyProxyTotalSize }}</template>
          </gl-sprintf>
        </span>
      </template>
    </gl-form-group>
    <gl-skeleton-loader v-else-if="$apollo.queries.group.loading" />

    <manifests-list
      :dependency-proxy-image-prefix="dependencyProxyImagePrefix"
      :loading="$apollo.queries.group.loading"
      :manifests="manifests"
      :pagination="pageInfo"
      @prev-page="fetchPreviousPage"
      @next-page="fetchNextPage"
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
