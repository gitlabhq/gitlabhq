<script>
import { GlCard, GlPagination, GlLoadingIcon } from '@gitlab/ui';
// eslint-disable-next-line no-restricted-imports
import { mapState, mapActions } from 'vuex';
import BlobHeader from '~/search/results/components/blob_header.vue';
import BlobFooter from '~/search/results/components/blob_footer.vue';
import BlobBody from '~/search/results/components/blob_body.vue';
import EmptyResult from '~/search/results/components/result_empty.vue';
import {
  getSystemColorScheme,
  listenSystemColorSchemeChange,
  removeListenerSystemColorSchemeChange,
} from '~/lib/utils/css_utils';

import { DEFAULT_SHOW_CHUNKS } from '~/search/results/constants';

export default {
  name: 'ZoektBlobResults',
  components: {
    GlCard,
    BlobHeader,
    BlobFooter,
    BlobBody,
    GlPagination,
    EmptyResult,
    GlLoadingIcon,
  },
  props: {
    blobSearch: {
      type: Object,
      required: true,
    },
    hasResults: {
      type: Boolean,
      required: true,
    },
    isLoading: {
      type: Boolean,
      required: true,
    },
  },
  data() {
    return {
      systemColorScheme: getSystemColorScheme(),
    };
  },
  computed: {
    ...mapState(['query']),
    pagination: {
      get() {
        return this.currentPage;
      },
      set(value) {
        this.setQuery({ key: 'page', value });
      },
    },
    currentPage() {
      return this.query.page ? parseInt(this.query.page, 10) : 1;
    },
  },
  mounted() {
    listenSystemColorSchemeChange(this.changeSystemColorScheme);
  },
  destroyed() {
    removeListenerSystemColorSchemeChange(this.changeSystemColorScheme);
  },
  methods: {
    ...mapActions(['setQuery']),
    hasMore(file) {
      const showingMatches = file.chunks
        .slice(0, DEFAULT_SHOW_CHUNKS)
        .reduce((acc, chunk) => acc + chunk.matchCountInChunk, 0);
      const matchesTotal = file.chunks.reduce((acc, chunk) => acc + chunk.matchCountInChunk, 0);

      return file.matchCount !== 0 && matchesTotal > showingMatches;
    },
    hasCode(file) {
      return file?.chunks.length > 0;
    },
    projectPathAndFilePath({ projectPath = '', path = '' }) {
      return `${projectPath}:${path}`;
    },
    position(index) {
      return index + 1;
    },
    changeSystemColorScheme(glScheme) {
      this.systemColorScheme = glScheme;
    },
  },
};
</script>

<template>
  <div class="gl-flex gl-flex-col gl-justify-center" :class="{ 'gl-mt-5': isLoading }">
    <gl-loading-icon v-if="isLoading" :label="__('Loading')" size="md" variant="spinner" />
    <div v-if="hasResults && !isLoading" class="gl-relative">
      <gl-card
        v-for="(file, index) in blobSearch.files"
        :key="projectPathAndFilePath(file)"
        class="file-result-holder file-holder gl-my-5"
        :header-class="{
          '!gl-border-b-0': !hasCode(file),
          'file-title': true,
        }"
        body-class="gl-p-0"
      >
        <template #header>
          <blob-header
            :file-path="file.path"
            :project-path="file.projectPath"
            :file-url="file.fileUrl"
            :is-header-only="!hasCode(file)"
            :system-color-scheme="systemColorScheme"
          />
        </template>

        <blob-body
          v-if="hasCode(file)"
          :file="file"
          :position="position(index)"
          :system-color-scheme="systemColorScheme"
        />

        <template v-if="hasMore(file)" #footer>
          <blob-footer :file="file" :position="position(index)" />
        </template>
      </gl-card>
    </div>
    <empty-result v-else-if="!hasResults && !isLoading" />
    <template v-if="hasResults && !isLoading">
      <gl-pagination
        v-model="pagination"
        class="gl-mx-auto"
        :per-page="blobSearch.perPage"
        :total-items="blobSearch.fileCount"
      />
    </template>
  </div>
</template>
