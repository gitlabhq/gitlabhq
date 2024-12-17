<script>
import { GlDisclosureDropdownItem } from '@gitlab/ui';

import { createAlert } from '~/alert';
import { s__, __, sprintf } from '~/locale';

import { confidentialityQueries } from '~/sidebar/queries/constants';
import { issuableTypeText } from '~/issues/constants';

export default {
  i18n: {
    enableConfidentiality: s__('WorkItem|Turn on confidentiality'),
    confidentialityEnabled: s__('WorkItem|Confidentiality turned on.'),
    disableConfidentiality: s__('WorkItem|Turn off confidentiality'),
    confidentialityDisabled: s__('WorkItem|Confidentiality turned off.'),
  },
  components: {
    GlDisclosureDropdownItem,
  },
  inject: ['iid', 'issueType', 'projectPath', 'fullPath'],
  data() {
    return {
      confidential: false,
    };
  },
  apollo: {
    confidential: {
      query() {
        return confidentialityQueries[this.issueType].query;
      },
      variables() {
        return {
          fullPath: this.fullPath,
          iid: String(this.iid),
        };
      },
      update(data) {
        return data.workspace?.issuable?.confidential || false;
      },
      skip() {
        return !this.iid;
      },
      error() {
        createAlert({
          message: sprintf(
            __('Something went wrong while getting %{issuableType} confidentiality status.'),
            {
              issuableType: this.issueTypeText,
            },
          ),
        });
      },
    },
  },
  computed: {
    issueTypeText() {
      const { issueType } = this;

      return issuableTypeText[issueType] ?? issueType;
    },
    confidentialItem() {
      return {
        text: this.confidential
          ? this.$options.i18n.disableConfidentiality
          : this.$options.i18n.enableConfidentiality,
      };
    },
    confidentialityText() {
      return this.confidential
        ? this.$options.i18n.confidentialityEnabled
        : this.$options.i18n.confidentialityDisabled;
    },
  },
  methods: {
    handleToggleWorkItemConfidentiality() {
      this.$apollo
        .mutate({
          mutation: confidentialityQueries[this.issueType].mutation,
          variables: {
            input: {
              iid: String(this.iid),
              projectPath: this.projectPath,
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
              this.$emit('closeActionsDropdown');
              this.$toast.show(this.confidentialityText);
            }
          },
        )
        .catch(() => {
          createAlert({
            message: sprintf(
              __('Something went wrong while setting %{issuableType} confidentiality.'),
              {
                issuableType: this.issueTypeText,
              },
            ),
          });
        });
    },
  },
};
</script>

<template>
  <gl-disclosure-dropdown-item
    :item="confidentialItem"
    data-testid="confidentiality-toggle-action"
    @action="handleToggleWorkItemConfidentiality"
  />
</template>
