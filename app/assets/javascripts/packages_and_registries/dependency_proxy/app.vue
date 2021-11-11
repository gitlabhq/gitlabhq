<script>
import {
  GlAlert,
  GlFormGroup,
  GlFormInputGroup,
  GlSkeletonLoader,
  GlSprintf,
  GlEmptyState,
} from '@gitlab/ui';
import { s__ } from '~/locale';
import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';
import TitleArea from '~/vue_shared/components/registry/title_area.vue';
import ManifestsList from '~/packages_and_registries/dependency_proxy/components/manifests_list.vue';
import {
  DEPENDENCY_PROXY_SETTINGS_DESCRIPTION,
  DEPENDENCY_PROXY_DOCS_PATH,
} from '~/packages_and_registries/settings/group/constants';
import { GRAPHQL_PAGE_SIZE } from '~/packages_and_registries/dependency_proxy/constants';

import getDependencyProxyDetailsQuery from '~/packages_and_registries/dependency_proxy/graphql/queries/get_dependency_proxy_details.query.graphql';

export default {
  components: {
    GlAlert,
    GlEmptyState,
    GlFormGroup,
    GlFormInputGroup,
    GlSkeletonLoader,
    GlSprintf,
    ClipboardButton,
    TitleArea,
    ManifestsList,
  },
  inject: ['groupPath', 'dependencyProxyAvailable', 'noManifestsIllustration'],
  i18n: {
    proxyNotAvailableText: s__(
      'DependencyProxy|Dependency Proxy feature is limited to public groups for now.',
    ),
    proxyDisabledText: s__(
      'DependencyProxy|Dependency Proxy disabled. To enable it, contact the group owner.',
    ),
    proxyImagePrefix: s__('DependencyProxy|Dependency Proxy image prefix'),
    copyImagePrefixText: s__('DependencyProxy|Copy prefix'),
    blobCountAndSize: s__('DependencyProxy|Contains %{count} blobs of images (%{size})'),
    pageTitle: s__('DependencyProxy|Dependency Proxy'),
    noManifestTitle: s__('DependencyProxy|There are no images in the cache'),
  },
  data() {
    return {
      group: {},
    };
  },
  apollo: {
    group: {
      query: getDependencyProxyDetailsQuery,
      skip() {
        return !this.dependencyProxyAvailable;
      },
      variables() {
        return this.queryVariables;
      },
    },
  },
  computed: {
    infoMessages() {
      return [
        {
          text: DEPENDENCY_PROXY_SETTINGS_DESCRIPTION,
          link: DEPENDENCY_PROXY_DOCS_PATH,
        },
      ];
    },
    dependencyProxyEnabled() {
      return this.group?.dependencyProxySetting?.enabled;
    },
    queryVariables() {
      return { fullPath: this.groupPath, first: GRAPHQL_PAGE_SIZE };
    },
    pageInfo() {
      return this.group.dependencyProxyManifests.pageInfo;
    },
    manifests() {
      return this.group.dependencyProxyManifests.nodes;
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
  },
};
</script>

<template>
  <div>
    <title-area :title="$options.i18n.pageTitle" :info-messages="infoMessages" />
    <gl-alert
      v-if="!dependencyProxyAvailable"
      :dismissible="false"
      data-testid="proxy-not-available"
    >
      {{ $options.i18n.proxyNotAvailableText }}
    </gl-alert>

    <gl-skeleton-loader v-else-if="$apollo.queries.group.loading" />

    <div v-else-if="dependencyProxyEnabled" data-testid="main-area">
      <gl-form-group :label="$options.i18n.proxyImagePrefix">
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
    </div>
    <gl-alert v-else :dismissible="false" data-testid="proxy-disabled">
      {{ $options.i18n.proxyDisabledText }}
    </gl-alert>
  </div>
</template>
