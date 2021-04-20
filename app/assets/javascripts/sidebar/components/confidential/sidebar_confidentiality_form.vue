<script>
import { GlSprintf, GlButton } from '@gitlab/ui';
import createFlash from '~/flash';
import { IssuableType } from '~/issue_show/constants';
import { __, sprintf } from '~/locale';
import { confidentialityQueries } from '~/sidebar/constants';

export default {
  i18n: {
    confidentialityOnWarning: __(
      'You are going to turn on confidentiality. Only team members with %{strongStart}at least Reporter access%{strongEnd} will be able to see and leave comments on the %{issuableType}.',
    ),
    confidentialityOffWarning: __(
      'You are going to turn off the confidentiality. This means %{strongStart}everyone%{strongEnd} will be able to see and leave a comment on this %{issuableType}.',
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
    workspacePath() {
      return this.issuableType === IssuableType.Issue
        ? {
            projectPath: this.fullPath,
          }
        : {
            groupPath: this.fullPath,
          };
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
              createFlash({
                message: errors[0],
              });
            } else {
              this.$emit('closeForm');
            }
          },
        )
        .catch(() => {
          createFlash({
            message: sprintf(
              __('Something went wrong while setting %{issuableType} confidentiality.'),
              {
                issuableType: this.issuableType,
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
              <strong>{{ content }}</strong>
            </template>
            <template #issuableType>{{ issuableType }}</template>
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
