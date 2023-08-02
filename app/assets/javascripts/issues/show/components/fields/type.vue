<!-- eslint-disable vue/multi-word-component-names -->
<script>
import { GlFormGroup, GlIcon, GlCollapsibleListbox } from '@gitlab/ui';
import { TYPE_INCIDENT, TYPE_ISSUE } from '~/issues/constants';
import { __ } from '~/locale';
import { issuableTypes } from '../../constants';
import getIssueStateQuery from '../../queries/get_issue_state.query.graphql';
import updateIssueStateMutation from '../../queries/update_issue_state.mutation.graphql';

export const i18n = {
  label: __('Issue Type'),
};

export default {
  i18n,
  issuableTypes,
  components: {
    GlFormGroup,
    GlIcon,
    GlCollapsibleListbox,
  },
  inject: {
    canCreateIncident: {
      default: false,
    },
    issueType: {
      default: TYPE_ISSUE,
    },
  },
  data() {
    return {
      issueState: {},
      selectedIssueType: '',
    };
  },
  apollo: {
    issueState: {
      query: getIssueStateQuery,
      result({
        data: {
          issueState: { issueType },
        },
      }) {
        this.selectedIssueType = issueType;
      },
    },
  },
  computed: {
    shouldShowIncident() {
      return this.issueType === TYPE_INCIDENT || this.canCreateIncident;
    },
  },
  methods: {
    updateIssueType(issueType) {
      this.$apollo.mutate({
        mutation: updateIssueStateMutation,
        variables: {
          issueType,
          isDirty: true,
        },
      });
    },
    isShown(type) {
      return type.value !== TYPE_INCIDENT || this.shouldShowIncident;
    },
  },
};
</script>

<template>
  <gl-form-group
    :label="$options.i18n.label"
    label-class="sr-only"
    label-for="issuable-type"
    class="gl-mb-0"
  >
    <gl-collapsible-listbox
      v-model="selectedIssueType"
      toggle-class="gl-mb-0"
      :items="$options.issuableTypes"
      :header-text="$options.i18n.label"
      :list-aria-labelled-by="$options.i18n.label"
      block
      @select="updateIssueType"
    >
      <template #list-item="{ item }">
        <span v-show="isShown(item)" data-testid="issue-type-list-item">
          <gl-icon :name="item.icon" />
          {{ item.text }}
        </span>
      </template>
    </gl-collapsible-listbox>
  </gl-form-group>
</template>
