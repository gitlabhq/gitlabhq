<script>
import { GlLink, GlLoadingIcon } from '@gitlab/ui';
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
    <div class="blob-viewer">
      <gl-loading-icon v-if="loading > 0" size="md" color="dark" class="my-4 mx-auto" />
      <div v-else-if="readme" v-html="readme.html"></div>
    </div>
  </article>
</template>
