<script>
import { joinPaths } from '~/lib/utils/url_utility';
import RefSelector from '~/vue_shared/components/ref/components/ref_selector.vue';
import CommitListBreadcrumb from './commit_list_breadcrumb.vue';

export default {
  name: 'CommitRefSelector',
  components: {
    RefSelector,
    CommitListBreadcrumb,
  },
  inject: ['projectId', 'escapedRef', 'rootRef'],
  props: {
    currentRef: {
      type: String,
      required: false,
      default: '',
    },
    currentRefType: {
      type: String,
      required: false,
      default: '',
    },
    filePath: {
      type: String,
      required: false,
      default: '',
    },
  },
  emits: ['ref-change'],
  computed: {
    refSelectorQueryParams() {
      return {
        sort: 'updated_desc',
      };
    },
    refSelectorValue() {
      const ref = this.currentRef || this.escapedRef;
      return this.currentRefType ? joinPaths('refs', this.currentRefType, ref) : ref;
    },
  },
  methods: {
    onRefChange(selectedRef) {
      const matches = selectedRef.match(/^refs\/(heads|tags)\/(.+)/) || [];
      const [, refType = null, actualRef = selectedRef] = matches;

      const query = { ...this.$route.query };
      if (refType) {
        query.ref_type = refType.toLowerCase();
      } else {
        delete query.ref_type;
      }

      // Use encodeURIComponent so the ref becomes a single path segment.
      // Slashes inside the ref are encoded as %2F, which lets the Vue
      // Router /:ref/:path* pattern parse the ref unambiguously — even
      // during browser back/forward navigation.
      const encodedRef = encodeURIComponent(actualRef);
      const path = `/${encodedRef}/${this.filePath || ''}`;

      this.$emit('ref-change', actualRef);
      this.$router.push({ path, query });
    },
  },
};
</script>

<template>
  <div class="gl-my-5 gl-flex gl-grow gl-gap-3">
    <ref-selector
      class="gl-max-w-26"
      data-testid="commits-ref-selector"
      :project-id="projectId"
      :value="refSelectorValue"
      :default-branch="rootRef"
      use-symbolic-ref-names
      :query-params="refSelectorQueryParams"
      @input="onRefChange"
    />

    <commit-list-breadcrumb class="gl-grow" :file-path="filePath" />
  </div>
</template>
