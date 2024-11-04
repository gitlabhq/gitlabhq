<script>
import { createAlert } from '~/alert';
import { joinPaths } from '~/lib/utils/url_utility';
import commitReferencesQuery from '../graphql/queries/commit_references.query.graphql';
import containingBranchesQuery from '../graphql/queries/commit_containing_branches.query.graphql';
import containingTagsQuery from '../graphql/queries/commit_containing_tags.query.graphql';
import {
  BRANCHES,
  TAGS,
  FETCH_CONTAINING_REFS_EVENT,
  FETCH_COMMIT_REFERENCES_ERROR,
  BRANCHES_REF_TYPE,
  TAGS_REF_TYPE,
} from '../constants';
import RefsList from './refs_list.vue';

export default {
  name: 'CommitRefs',
  components: {
    RefsList,
  },
  inject: ['fullPath', 'commitSha'],
  apollo: {
    // eslint-disable-next-line @gitlab/vue-no-undef-apollo-properties
    project: {
      query: commitReferencesQuery,
      variables() {
        return this.queryVariables;
      },
      update({
        project: {
          commitReferences: { tippingTags, tippingBranches, containingBranches, containingTags },
        },
      }) {
        this.tippingTags = tippingTags.names;
        this.tippingBranches = tippingBranches.names;
        this.hasContainingBranches = Boolean(containingBranches.names.length);
        this.hasContainingTags = Boolean(containingTags.names.length);
      },
      error() {
        createAlert({
          message: this.$options.i18n.errorMessage,
          captureError: true,
        });
      },
    },
  },
  data() {
    return {
      containingTags: [],
      containingBranches: [],
      tippingTags: [],
      tippingBranches: [],
      hasContainingBranches: false,
      hasContainingTags: false,
    };
  },
  computed: {
    hasBranches() {
      return this.tippingBranches.length || this.hasContainingBranches;
    },
    hasTags() {
      return this.tippingTags.length || this.hasContainingTags;
    },
    queryVariables() {
      return {
        fullPath: this.fullPath,
        commitSha: this.commitSha,
      };
    },
    commitsUrlPart() {
      const urlPart = joinPaths(gon.relative_url_root || '', `/${this.fullPath}`, `/-/commits/`);
      return urlPart;
    },
    isLoading() {
      return this.$apollo.queries.project.loading;
    },
  },
  methods: {
    async fetchContainingRefs({ query, namespace }) {
      try {
        const { data } = await this.$apollo.query({
          query,
          variables: this.queryVariables,
        });
        this[namespace] = data.project.commitReferences[namespace].names;
        return data.project.commitReferences[namespace].names;
      } catch {
        return createAlert({
          message: this.$options.i18n.errorMessage,
          captureError: true,
        });
      }
    },
    fetchContainingBranches() {
      this.fetchContainingRefs({ query: containingBranchesQuery, namespace: 'containingBranches' });
    },
    fetchContainingTags() {
      this.fetchContainingRefs({ query: containingTagsQuery, namespace: 'containingTags' });
    },
  },
  i18n: {
    branches: BRANCHES,
    tags: TAGS,
    errorMessage: FETCH_COMMIT_REFERENCES_ERROR,
  },
  FETCH_CONTAINING_REFS_EVENT,
  BRANCHES_REF_TYPE,
  TAGS_REF_TYPE,
};
</script>

<template>
  <div class="gl-border-t gl-border-t-section">
    <div class="well-segment">
      <refs-list
        :has-containing-refs="hasContainingBranches"
        :is-loading="isLoading"
        :tipping-refs="tippingBranches"
        :containing-refs="containingBranches"
        :namespace="$options.i18n.branches"
        :url-part="commitsUrlPart"
        :ref-type="$options.BRANCHES_REF_TYPE"
        @[$options.FETCH_CONTAINING_REFS_EVENT]="fetchContainingBranches"
      />
    </div>
    <div class="well-segment">
      <refs-list
        :has-containing-refs="hasContainingTags"
        :is-loading="isLoading"
        :tipping-refs="tippingTags"
        :containing-refs="containingTags"
        :namespace="$options.i18n.tags"
        :url-part="commitsUrlPart"
        :ref-type="$options.TAGS_REF_TYPE"
        @[$options.FETCH_CONTAINING_REFS_EVENT]="fetchContainingTags"
      />
    </div>
  </div>
</template>
