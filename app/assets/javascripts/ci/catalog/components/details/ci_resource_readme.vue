<script>
import { GlLoadingIcon } from '@gitlab/ui';
import { createAlert } from '~/alert';
import { __ } from '~/locale';
import SafeHtml from '~/vue_shared/directives/safe_html';
import { renderGFM } from '~/behaviors/markdown/render_gfm';
import getCiCatalogResourceReadme from '../../graphql/queries/get_ci_catalog_resource_readme.query.graphql';

export default {
  components: {
    GlLoadingIcon,
  },
  directives: { SafeHtml },
  props: {
    resourcePath: {
      type: String,
      required: true,
    },
    version: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      readmeHtml: null,
    };
  },
  apollo: {
    readmeHtml: {
      query: getCiCatalogResourceReadme,
      variables() {
        return {
          fullPath: this.resourcePath,
          version: this.version,
        };
      },
      update(data) {
        return data?.ciCatalogResource?.versions?.nodes[0]?.readmeHtml || null;
      },
      error() {
        createAlert({ message: this.$options.i18n.loadingError });
      },
    },
  },
  computed: {
    isLoading() {
      return this.$apollo?.queries.readmeHtml.loading;
    },
  },
  watch: {
    readmeHtml(newVal) {
      if (newVal) {
        this.$nextTick(() => {
          renderGFM(this.$refs.readme);
        });
      }
    },
  },
  i18n: {
    loadingError: __("There was a problem loading this project's readme content."),
  },
};
</script>
<template>
  <div>
    <gl-loading-icon v-if="isLoading" class="gl-mt-5" size="lg" />
    <div v-else ref="readme" v-safe-html="readmeHtml" class="md"></div>
  </div>
</template>
