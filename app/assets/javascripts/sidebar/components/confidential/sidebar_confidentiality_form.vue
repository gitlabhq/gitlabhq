<script>
import { GlSprintf, GlButton } from '@gitlab/ui';
import { createAlert } from '~/alert';
import { TYPE_ISSUE, TYPE_TEST_CASE, issuableTypeText } from '~/issues/constants';
import { __, sprintf } from '~/locale';
import { confidentialityQueries } from '../../queries/constants';

export default {
  i18n: {
    confidentialityOnWarning: __(
      'You are going to turn on confidentiality. Only %{context} members with %{strongStart}%{permissions}%{strongEnd} can view or be notified about this %{issuableType}.',
    ),
    confidentialityOffWarning: __(
      'You are going to turn off the confidentiality. This means %{strongStart}everyone%{strongEnd} will be able to see%{commentText} this %{issuableType}.',
    ),
  },
  components: {
    GlSprintf,
    GlButton,
  },
  props: {
    iid: {
      type: String,
      required: true,
    },
    fullPath: {
      type: String,
      required: true,
    },
    confidential: {
      required: true,
      type: Boolean,
    },
    issuableType: {
      required: true,
      type: String,
    },
  },
  data() {
    return {
      loading: false,
    };
  },
  computed: {
    toggleButtonText() {
      if (this.loading) {
        return __('Applying');
      }
      return this.confidential ? __('Turn off') : __('Turn on');
    },
    warningMessage() {
      return this.confidential
        ? this.$options.i18n.confidentialityOffWarning
        : this.$options.i18n.confidentialityOnWarning;
    },
    isIssue() {
      return this.issuableType === TYPE_ISSUE;
    },
    isTestCase() {
      return this.issuableType === TYPE_TEST_CASE;
    },
    isIssueOrTestCase() {
      return this.isIssue || this.isTestCase;
    },
    context() {
      return this.isIssueOrTestCase ? __('project') : __('group');
    },
    workspacePath() {
      return this.isIssueOrTestCase
        ? {
            projectPath: this.fullPath,
          }
        : {
            groupPath: this.fullPath,
          };
    },
    permissions() {
      return this.isIssue
        ? __('at least the Planner role, the author, and assignees')
        : __('at least the Planner role');
    },
    issuableTypeText() {
      return issuableTypeText[this.issuableType];
    },
    commentText() {
      return this.isTestCase ? '' : __(' and leave a comment on');
    },
  },
  methods: {
    submitForm() {
      this.loading = true;
      this.$apollo
        .mutate({
          mutation: confidentialityQueries[this.issuableType].mutation,
          variables: {
            input: {
              ...this.workspacePath,
              iid: this.iid,
              confidential: !this.confidential,
            },
          },
        })
        .then(
          ({
            data: {
              issuableSetConfidential: { errors },
            },
          }) => {
            if (errors.length) {
              createAlert({
                message: errors[0],
              });
            } else {
              this.$emit('closeForm');
            }
          },
        )
        .catch(() => {
          createAlert({
            message: sprintf(
              __('Something went wrong while setting %{issuableType} confidentiality.'),
              {
                issuableType: this.issuableTypeText,
              },
            ),
          });
        })
        .finally(() => {
          this.loading = false;
        });
    },
  },
};
</script>

<template>
  <div class="dropdown show">
    <div class="dropdown-menu sidebar-item-warning-message">
      <div>
        <p data-testid="warning-message">
          <gl-sprintf :message="warningMessage">
            <template #strong="{ content }">
              <strong>
                <gl-sprintf :message="content">
                  <template #permissions>{{ permissions }}</template>
                </gl-sprintf>
              </strong>
            </template>
            <template #context>{{ context }}</template>
            <template #commentText>{{ commentText }}</template>
            <template #issuableType>{{ issuableTypeText }}</template>
          </gl-sprintf>
        </p>
        <div class="sidebar-item-warning-message-actions">
          <gl-button class="gl-mr-3" data-testid="confidential-cancel" @click="$emit('closeForm')">
            {{ __('Cancel') }}
          </gl-button>
          <gl-button
            category="secondary"
            variant="confirm"
            :disabled="loading"
            :loading="loading"
            data-testid="confidential-toggle"
            @click.prevent="submitForm"
          >
            {{ toggleButtonText }}
          </gl-button>
        </div>
      </div>
    </div>
  </div>
</template>
