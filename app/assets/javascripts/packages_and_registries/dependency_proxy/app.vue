<script>
import { GlAlert, GlFormGroup, GlFormInputGroup, GlSkeletonLoader, GlSprintf } from '@gitlab/ui';
import { s__ } from '~/locale';
import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';
import TitleArea from '~/vue_shared/components/registry/title_area.vue';
import {
  DEPENDENCY_PROXY_SETTINGS_DESCRIPTION,
  DEPENDENCY_PROXY_DOCS_PATH,
} from '~/packages_and_registries/settings/group/constants';
import { GRAPHQL_PAGE_SIZE } from '~/packages_and_registries/dependency_proxy/constants';

import getDependencyProxyDetailsQuery from '~/packages_and_registries/dependency_proxy/graphql/queries/get_dependency_proxy_details.query.graphql';

export default {
  components: {
    GlFormGroup,
    GlAlert,
    GlFormInputGroup,
    GlSprintf,
    ClipboardButton,
    TitleArea,
    GlSkeletonLoader,
  },
  inject: ['groupPath', 'dependencyProxyAvailable'],
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
        return { fullPath: this.groupPath, first: GRAPHQL_PAGE_SIZE };
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
    </div>
    <gl-alert v-else :dismissible="false" data-testid="proxy-disabled">
      {{ $options.i18n.proxyDisabledText }}
    </gl-alert>
  </div>
</template>
