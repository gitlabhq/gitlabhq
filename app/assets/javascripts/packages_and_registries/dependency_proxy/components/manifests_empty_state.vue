<script>
import { GlEmptyState, GlFormGroup, GlFormInputGroup, GlLink, GlSprintf } from '@gitlab/ui';
import { s__ } from '~/locale';
import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';
import { DEPENDENCY_PROXY_HELP_PAGE_PATH } from '~/packages_and_registries/dependency_proxy/constants';

export default {
  name: 'ManifestsEmptyState',
  components: {
    ClipboardButton,
    GlEmptyState,
    GlFormGroup,
    GlFormInputGroup,
    GlLink,
    GlSprintf,
  },
  inject: ['noManifestsIllustration'],
  i18n: {
    codeExampleLabel: s__('DependencyProxy|Pull image by digest example'),
    noManifestTitle: s__('DependencyProxy|There are no images in the cache'),
    emptyText: s__(
      'DependencyProxy|To store docker images in Dependency Proxy cache, pull an image by tag in your %{codeStart}.gitlab-ci.yml%{codeEnd} file. In this example, the image is %{codeStart}alpine:latest%{codeEnd}',
    ),
    documentationText: s__(
      'DependencyProxy|%{docLinkStart}See the documentation%{docLinkEnd} for other ways to store Docker images in Dependency Proxy cache.',
    ),
    copyExample: s__('DependencyProxy|Copy example'),
  },
  // eslint-disable-next-line no-template-curly-in-string
  codeExample: 'image: ${CI_DEPENDENCY_PROXY_DIRECT_GROUP_IMAGE_PREFIX}/alpine:latest',
  links: {
    DEPENDENCY_PROXY_HELP_PAGE_PATH,
  },
};
</script>

<template>
  <gl-empty-state :svg-path="noManifestsIllustration" :title="$options.i18n.noManifestTitle">
    <template #description>
      <p class="gl-mb-5">
        <gl-sprintf :message="$options.i18n.emptyText">
          <template #code="{ content }">
            <code>{{ content }}</code>
          </template>
        </gl-sprintf>
      </p>

      <gl-form-group
        class="gl-mb-5"
        :label="$options.i18n.codeExampleLabel"
        label-for="code-example"
        label-sr-only
      >
        <gl-form-input-group
          id="code-example"
          readonly
          :value="$options.codeExample"
          class="gl-mx-auto gl-w-7/10"
          select-on-click
        >
          <template #append>
            <clipboard-button
              :text="$options.codeExample"
              :title="$options.i18n.copyExample"
              class="!gl-m-0"
            />
          </template>
        </gl-form-input-group>
      </gl-form-group>

      <p>
        <gl-sprintf :message="$options.i18n.documentationText">
          <template #docLink="{ content }">
            <gl-link :href="$options.links.DEPENDENCY_PROXY_HELP_PAGE_PATH">{{ content }}</gl-link>
          </template>
        </gl-sprintf>
      </p>
    </template>
  </gl-empty-state>
</template>
