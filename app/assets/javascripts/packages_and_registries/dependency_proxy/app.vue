<script>
import { GlAlert, GlFormGroup, GlFormInputGroup, GlSkeletonLoader, GlSprintf } from '@gitlab/ui';
import { helpPagePath } from '~/helpers/help_page_helper';
import { __ } from '~/locale';
import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';
import TitleArea from '~/vue_shared/components/registry/title_area.vue';

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
    subTitle: __(
      'Create a local proxy for storing frequently used upstream images. %{docLinkStart}Learn more%{docLinkEnd} about dependency proxies.',
    ),
    proxyNotAvailableText: __('Dependency proxy feature is limited to public groups for now.'),
    proxyImagePrefix: __('Dependency proxy image prefix'),
    copyImagePrefixText: __('Copy prefix'),
    blobCountAndSize: __('Contains %{count} blobs of images (%{size})'),
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
        return { fullPath: this.groupPath };
      },
    },
  },
  computed: {
    infoMessages() {
      return [
        {
          text: this.$options.i18n.subTitle,
          link: helpPagePath('user/packages/dependency_proxy/index'),
        },
      ];
    },
  },
};
</script>

<template>
  <div>
    <title-area :title="__('Dependency Proxy')" :info-messages="infoMessages" />
    <gl-alert v-if="!dependencyProxyAvailable" :dismissible="false">
      {{ $options.i18n.proxyNotAvailableText }}
    </gl-alert>

    <gl-skeleton-loader v-else-if="$apollo.queries.group.loading" />

    <div v-else data-testid="main-area">
      <gl-form-group :label="$options.i18n.proxyImagePrefix">
        <gl-form-input-group
          readonly
          :value="group.dependencyProxyImagePrefix"
          class="gl-layout-w-limited"
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
  </div>
</template>
