<script>
import $ from 'jquery';
import '~/behaviors/markdown/render_gfm';
import { GlLink, GlLoadingIcon } from '@gitlab/ui';
import { handleLocationHash } from '~/lib/utils/common_utils';
import getReadmeQuery from '../../queries/getReadme.query.graphql';

export default {
  apollo: {
    readme: {
      query: getReadmeQuery,
      variables() {
        return {
          url: this.blob.webUrl,
        };
      },
      loadingKey: 'loading',
    },
  },
  components: {
    GlLink,
    GlLoadingIcon,
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
      loading: 0,
    };
  },
  watch: {
    readme(newVal) {
      if (newVal) {
        this.$nextTick(() => {
          handleLocationHash();
          $(this.$refs.readme).renderGFM();
        });
      }
    },
  },
};
</script>

<template>
  <article class="file-holder limited-width-container readme-holder">
    <div class="js-file-title file-title-flex-parent">
      <div class="file-header-content">
        <i aria-hidden="true" class="fa fa-file-text-o fa-fw"></i>
        <gl-link :href="blob.webUrl">
          <strong>{{ blob.name }}</strong>
        </gl-link>
      </div>
    </div>
    <div class="blob-viewer" data-qa-selector="blob_viewer_content">
      <gl-loading-icon v-if="loading > 0" size="md" color="dark" class="my-4 mx-auto" />
      <div v-else-if="readme" ref="readme" v-html="readme.html"></div>
    </div>
  </article>
</template>
