<script>
import { GlButton, GlIcon, GlPopover } from '@gitlab/ui';
import { s__ } from '~/locale';
import titleRegexQuery from '~/vue_merge_request_widget/queries/title_regex.query.graphql';
import mergeRequestQueryVariablesMixin from '~/vue_merge_request_widget/mixins/merge_request_query_variables';
import ActionButtons from '../action_buttons.vue';
import MergeChecksMessage from './message.vue';

export default {
  name: 'MergeChecksTitleRegex',
  components: {
    GlButton,
    GlIcon,
    GlPopover,
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
          text: s__('mrWidget|Edit title'),
          category: 'default',
          href: this.mrEditPath,
        },
      ];
    },
    titleRegex() {
      return this.project?.mergeRequestTitleRegex;
    },
    titleRegexDescription() {
      return this.project?.mergeRequestTitleRegexDescription;
    },
    hasPopoverContent() {
      return this.titleRegexDescription || this.titleRegex;
    },
  },
};
</script>

<template>
  <merge-checks-message :check="check">
    <template v-if="hasPopoverContent">
      <gl-button
        id="title-regex-help"
        variant="link"
        class="gl-mr-3"
        :aria-label="__('Learn more')"
      >
        <gl-icon name="question-o" />
      </gl-button>
      <gl-popover
        target="title-regex-help"
        :title="s__('mrWidget|Naming convention')"
        placement="top"
      >
        <p v-if="titleRegexDescription" class="gl-mb-2">{{ titleRegexDescription }}</p>
        <code v-if="titleRegex">{{ titleRegex }}</code>
      </gl-popover>
    </template>
    <template #failed>
      <action-buttons :tertiary-buttons="tertiaryActionsButtons" />
    </template>
  </merge-checks-message>
</template>
