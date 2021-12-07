<script>
import { GlFormGroup, GlDropdown, GlDropdownItem, GlIcon } from '@gitlab/ui';
import { capitalize } from 'lodash';
import { __ } from '~/locale';
import { IssuableTypes, IncidentType } from '../../constants';
import getIssueStateQuery from '../../queries/get_issue_state.query.graphql';
import updateIssueStateMutation from '../../queries/update_issue_state.mutation.graphql';

export const i18n = {
  label: __('Issue Type'),
};

export default {
  i18n,
  IssuableTypes,
  components: {
    GlFormGroup,
    GlIcon,
    GlDropdown,
    GlDropdownItem,
  },
  inject: {
    canCreateIncident: {
      default: false,
    },
    issueType: {
      default: 'issue',
    },
  },
  data() {
    return {
      issueState: {},
    };
  },
  apollo: {
    issueState: {
      query: getIssueStateQuery,
    },
  },
  computed: {
    dropdownText() {
      const {
        issueState: { issueType },
      } = this;
      return capitalize(issueType);
    },
    shouldShowIncident() {
      return this.issueType === IncidentType || this.canCreateIncident;
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
      return type.value !== IncidentType || this.shouldShowIncident;
    },
  },
};
</script>

<template>
  <gl-form-group
    :label="$options.i18n.label"
    label-class="sr-only"
    label-for="issuable-type"
    class="mb-2 mb-md-0"
  >
    <gl-dropdown
      id="issuable-type"
      :aria-labelledby="$options.i18n.label"
      :text="dropdownText"
      :header-text="$options.i18n.label"
      class="gl-w-full"
      toggle-class="dropdown-menu-toggle"
    >
      <gl-dropdown-item
        v-for="type in $options.IssuableTypes"
        v-show="isShown(type)"
        :key="type.value"
        :is-checked="issueState.issueType === type.value"
        is-check-item
        @click="updateIssueType(type.value)"
      >
        <gl-icon :name="type.icon" />
        {{ type.text }}
      </gl-dropdown-item>
    </gl-dropdown>
  </gl-form-group>
</template>
