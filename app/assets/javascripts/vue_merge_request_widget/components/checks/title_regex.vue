<script>
import { s__ } from '~/locale';
import titleRegexQuery from '~/vue_merge_request_widget/queries/title_regex.query.graphql';
import mergeRequestQueryVariablesMixin from '~/vue_merge_request_widget/mixins/merge_request_query_variables';
import ActionButtons from '../action_buttons.vue';
import MergeChecksMessage from './message.vue';

export default {
  name: 'MergeChecksTitleRegex',
  components: {
    MergeChecksMessage,
    ActionButtons,
  },
  mixins: [mergeRequestQueryVariablesMixin],
  apollo: {
    project: {
      query: titleRegexQuery,
      variables() {
        return {
          projectPath: this.mr.targetProjectFullPath,
        };
      },
      update: (data) => data.project,
    },
  },
  props: {
    check: {
      type: Object,
      required: true,
    },
    mr: {
      type: Object,
      required: false,
      default: () => ({}),
    },
  },
  data() {
    return {
      project: null,
    };
  },
  computed: {
    mrEditPath() {
      let { pathname } = document.location;

      pathname = pathname.replace(/\/$/, '');

      return `${pathname}/edit`;
    },
    tertiaryActionsButtons() {
      return [
        {
          text: s__('mrWidget|Edit merge request'),
          category: 'default',
          href: this.mrEditPath,
        },
      ];
    },
    titleRegexDescription() {
      return this.project?.mergeRequestTitleRegexDescription;
    },
  },
};
</script>

<template>
  <merge-checks-message :check="check">
    <template #reason-footer>
      <p v-if="titleRegexDescription" class="gl-mb-0 gl-mt-2 gl-text-subtle">
        {{ titleRegexDescription }}
      </p>
    </template>
    <template #failed>
      <action-buttons :tertiary-buttons="tertiaryActionsButtons" />
    </template>
  </merge-checks-message>
</template>
