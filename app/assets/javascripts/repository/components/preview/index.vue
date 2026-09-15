<script>
import { GlButton, GlIcon, GlLink, GlLoadingIcon } from '@gitlab/ui';
import SafeHtml from '~/vue_shared/directives/safe_html';
import { __, sprintf } from '~/locale';
import { handleLocationHash, isLoggedIn } from '~/lib/utils/common_utils';
import { renderGFM } from '~/behaviors/markdown/render_gfm';
import { logError } from '~/lib/logger';
import { captureException } from '~/sentry/sentry_browser_wrapper';
import { getRefType } from '../../utils/ref_type';
import getRefMixin, { refApolloQuery } from '../../mixins/get_ref';
import projectPathQuery from '../../queries/project_path.query.graphql';
import blobEditQuery from '../../queries/blob_edit.query.graphql';
import readmeQuery from '../../queries/readme.query.graphql';

export default {
  name: 'PreviewIndex',
  components: {
    GlButton,
    GlIcon,
    GlLink,
    GlLoadingIcon,
  },
  directives: {
    SafeHtml,
  },
  mixins: [getRefMixin],
  apollo: {
    // Re-declared from getRefMixin: Vue 3 drops mixin apollo entries when the
    // component defines its own apollo block (see mixins/get_ref.js).
    ref: refApolloQuery,
    readme: {
      query: readmeQuery,
      variables() {
        return {
          url: this.blob.webPath,
        };
      },
    },
    projectPath: {
      query: projectPathQuery,
    },
    editBlob: {
      query: blobEditQuery,
      variables() {
        return {
          projectPath: this.projectPath,
          filePath: this.blob.path,
          ref: this.ref,
          refType: getRefType(this.refType),
        };
      },
      skip() {
        return !isLoggedIn() || !this.projectPath || !this.ref || !this.blob.path;
      },
      update: (data) => data.project?.repository?.blobs?.nodes?.[0] ?? null,
      error(error) {
        logError(`Unexpected error while fetching editBlob query`, error);
        captureException(error);
      },
    },
  },
  inject: {
    refType: {
      default: null,
    },
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
      projectPath: '',
      editBlob: null,
      ref: '',
    };
  },
  computed: {
    isLoading() {
      return this.$apollo.queries.readme.loading;
    },
    editPath() {
      return this.editBlob?.canModifyBlob ? this.editBlob.editBlobPath : null;
    },
    editButtonAriaLabel() {
      return sprintf(__('Edit file %{fileName}'), { fileName: this.blob.name });
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
    <div class="js-file-title file-title-flex-parent gl-px-4 gl-py-3">
      <div class="file-header-content">
        <gl-icon name="doc-text" />
        <gl-link :href="blob.webPath">
          <strong>{{ blob.name }}</strong>
        </gl-link>
      </div>
      <gl-button
        v-if="editPath"
        category="tertiary"
        :href="editPath"
        :aria-label="editButtonAriaLabel"
        data-testid="edit-readme-button"
      >
        {{ __('Edit file') }}
      </gl-button>
    </div>
    <div class="blob-viewer" data-testid="blob-viewer-content" itemprop="about">
      <gl-loading-icon v-if="isLoading" size="lg" color="dark" class="gl-mx-auto gl-my-6" />
      <div
        v-else-if="readme"
        ref="readme"
        v-safe-html:[$options.safeHtmlConfig]="readme.html"
      ></div>
    </div>
  </article>
</template>
