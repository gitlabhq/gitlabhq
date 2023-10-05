<!-- eslint-disable vue/multi-word-component-names -->
<script>
import { GlIcon, GlLink, GlLoadingIcon } from '@gitlab/ui';
import SafeHtml from '~/vue_shared/directives/safe_html';
import { handleLocationHash } from '~/lib/utils/common_utils';
import { renderGFM } from '~/behaviors/markdown/render_gfm';
import readmeQuery from '../../queries/readme.query.graphql';

export default {
  apollo: {
    readme: {
      query: readmeQuery,
      variables() {
        return {
          url: this.blob.webPath,
        };
      },
    },
  },
  components: {
    GlIcon,
    GlLink,
    GlLoadingIcon,
  },
  directives: {
    SafeHtml,
  },
  props: {
    blob: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      readme: null,
    };
  },
  computed: {
    isLoading() {
      return this.$apollo.queries.readme.loading;
    },
  },
  watch: {
    readme(newVal) {
      if (newVal) {
        this.$nextTick(() => {
          handleLocationHash();
          renderGFM(this.$refs.readme);
        });
      }
    },
  },
  safeHtmlConfig: {
    ADD_TAGS: ['copy-code'],
  },
};
</script>

<template>
  <article class="file-holder limited-width-container readme-holder">
    <div class="js-file-title file-title-flex-parent">
      <div class="file-header-content">
        <gl-icon name="doc-text" />
        <gl-link :href="blob.webPath">
          <strong>{{ blob.name }}</strong>
        </gl-link>
      </div>
    </div>
    <div class="blob-viewer" data-testid="blob-viewer-content" itemprop="about">
      <gl-loading-icon v-if="isLoading" size="lg" color="dark" class="my-4 mx-auto" />
      <div
        v-else-if="readme"
        ref="readme"
        v-safe-html:[$options.safeHtmlConfig]="readme.html"
      ></div>
    </div>
  </article>
</template>
