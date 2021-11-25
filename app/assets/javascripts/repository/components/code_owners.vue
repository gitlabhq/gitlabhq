<script>
import { GlIcon, GlLink } from '@gitlab/ui';
import { __ } from '~/locale';
import createFlash from '~/flash';
import { helpPagePath } from '~/helpers/help_page_helper';
import codeOwnersInfoQuery from '../queries/code_owners_info.query.graphql';
import getRefMixin from '../mixins/get_ref';

export default {
  i18n: {
    title: __('Code owners'),
    about: __('About this feature'),
    andSeparator: __('and'),
    errorMessage: __('An error occurred while loading code owners.'),
  },
  codeOwnersHelpPath: helpPagePath('user/project/code_owners'),
  components: {
    GlIcon,
    GlLink,
  },
  mixins: [getRefMixin],
  apollo: {
    project: {
      query: codeOwnersInfoQuery,
      variables() {
        return {
          projectPath: this.projectPath,
          filePath: this.filePath,
          ref: this.ref,
        };
      },
      skip() {
        return !this.filePath;
      },
      result() {
        this.isFetching = false;
      },
      error() {
        createFlash({ message: this.$options.i18n.errorMessage });
      },
    },
  },
  props: {
    projectPath: {
      type: String,
      required: true,
    },
    filePath: {
      type: String,
      required: false,
      default: null,
    },
  },
  data() {
    return {
      isFetching: false,
      project: {
        repository: {
          blobs: {
            nodes: [
              {
                codeOwners: [],
              },
            ],
          },
        },
      },
    };
  },
  computed: {
    blobInfo() {
      return this.project?.repository?.blobs?.nodes[0];
    },
    codeOwners() {
      return this.blobInfo?.codeOwners || [];
    },
    hasCodeOwners() {
      return this.filePath && Boolean(this.codeOwners.length);
    },
    commaSeparateList() {
      return this.codeOwners.length > 2;
    },
    showAndSeparator() {
      return this.codeOwners.length > 1;
    },
    lastListItem() {
      return this.codeOwners.length - 1;
    },
  },
  watch: {
    filePath() {
      this.isFetching = true;
      this.$apollo.queries.project.refetch();
    },
  },
};
</script>

<template>
  <div
    v-if="hasCodeOwners && !isFetching"
    class="well-segment blob-auxiliary-viewer file-owner-content qa-file-owner-content"
  >
    <gl-icon name="users" data-testid="users-icon" />
    <strong>{{ $options.i18n.title }}</strong>
    <gl-link :href="$options.codeOwnersHelpPath" target="_blank" :title="$options.i18n.about">
      <gl-icon name="question-o" data-testid="help-icon" />
    </gl-link>
    :
    <div
      v-for="(owner, index) in codeOwners"
      :key="index"
      :class="[
        { 'gl-display-inline-block': commaSeparateList, 'gl-display-inline': !commaSeparateList },
      ]"
      data-testid="code-owners"
    >
      <span v-if="commaSeparateList && index > 0" data-testid="comma-separator">,</span>
      <span v-if="showAndSeparator && index === lastListItem" data-testid="and-separator">{{
        $options.i18n.andSeparator
      }}</span>
      <gl-link :href="owner.webPath" target="_blank" :title="$options.i18n.about">
        {{ owner.name }}
      </gl-link>
    </div>
  </div>
</template>
