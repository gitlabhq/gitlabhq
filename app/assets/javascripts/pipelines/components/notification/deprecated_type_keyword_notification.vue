<script>
import { GlAlert, GlLink, GlSprintf } from '@gitlab/ui';
import { __ } from '~/locale';
import getPipelineWarnings from '../../graphql/queries/get_pipeline_warnings.query.graphql';

export default {
  // eslint-disable-next-line @gitlab/require-i18n-strings
  expectedMessage: 'will be removed in',
  i18n: {
    title: __('Found warning in your .gitlab-ci.yml'),
    rootTypesWarning: __(
      '%{codeStart}types%{codeEnd} is deprecated and will be removed in 15.0. Use %{codeStart}stages%{codeEnd} instead. %{linkStart}Learn More %{linkEnd}',
    ),
    typeWarning: __(
      '%{codeStart}type%{codeEnd} is deprecated and will be removed in 15.0. Use %{codeStart}stage%{codeEnd} instead. %{linkStart}Learn More %{linkEnd}',
    ),
  },
  components: {
    GlAlert,
    GlLink,
    GlSprintf,
  },
  inject: ['deprecatedKeywordsDocPath', 'fullPath', 'pipelineIid'],
  apollo: {
    warnings: {
      query: getPipelineWarnings,
      variables() {
        return {
          fullPath: this.fullPath,
          iid: this.pipelineIid,
        };
      },
      update(data) {
        return data?.project?.pipeline?.warningMessages || [];
      },
      error() {
        this.hasError = true;
      },
    },
  },
  data() {
    return {
      warnings: [],
      hasError: false,
    };
  },
  computed: {
    deprecationWarnings() {
      return this.warnings.filter(({ content }) => {
        return content.includes(this.$options.expectedMessage);
      });
    },
    formattedWarnings() {
      // The API doesn't have a mechanism currently to return a
      // type instead of just the error message. To work around this,
      // we check if the deprecation message is found within the warnings
      // and show a FE version of that message with the link to the documentation
      // and translated. We can have only 2 types of warnings: root types and individual
      // type. If the word `root` is present, then we know it's the root type deprecation
      // and if not, it's the normal type. This has to be deleted in 15.0.
      // Follow-up issue: https://gitlab.com/gitlab-org/gitlab/-/issues/350810
      return this.deprecationWarnings.map(({ content }) => {
        if (content.includes('root')) {
          return this.$options.i18n.rootTypesWarning;
        }
        return this.$options.i18n.typeWarning;
      });
    },
    hasDeprecationWarning() {
      return this.formattedWarnings.length > 0;
    },
    showWarning() {
      return (
        !this.$apollo.queries.warnings?.loading && !this.hasError && this.hasDeprecationWarning
      );
    },
  },
};
</script>
<template>
  <div>
    <gl-alert
      v-if="showWarning"
      :title="$options.i18n.title"
      variant="warning"
      :dismissible="false"
    >
      <ul class="gl-mb-0">
        <li v-for="warning in formattedWarnings" :key="warning">
          <gl-sprintf :message="warning">
            <template #code="{ content }">
              <code> {{ content }}</code>
            </template>
            <template #link="{ content }">
              <gl-link :href="deprecatedKeywordsDocPath" target="_blank"> {{ content }}</gl-link>
            </template>
          </gl-sprintf>
        </li>
      </ul>
    </gl-alert>
  </div>
</template>
