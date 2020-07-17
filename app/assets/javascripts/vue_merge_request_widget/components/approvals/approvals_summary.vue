<script>
import { n__, sprintf } from '~/locale';
import { toNounSeriesText } from '~/lib/utils/grammar';
import UserAvatarList from '~/vue_shared/components/user_avatar/user_avatar_list.vue';
import { APPROVED_MESSAGE } from '~/vue_merge_request_widget/components/approvals/messages';

export default {
  components: {
    UserAvatarList,
  },
  props: {
    approved: {
      type: Boolean,
      required: true,
    },
    approvalsLeft: {
      type: Number,
      required: true,
    },
    rulesLeft: {
      type: Array,
      required: false,
      default: () => [],
    },
    approvers: {
      type: Array,
      required: false,
      default: () => [],
    },
  },
  computed: {
    message() {
      if (this.approved) {
        return APPROVED_MESSAGE;
      }

      if (!this.rulesLeft.length) {
        return n__('Requires approval.', 'Requires %d more approvals.', this.approvalsLeft);
      }

      return sprintf(
        n__(
          'Requires approval from %{names}.',
          'Requires %{count} more approvals from %{names}.',
          this.approvalsLeft,
        ),
        {
          names: toNounSeriesText(this.rulesLeft),
          count: this.approvalsLeft,
        },
        false,
      );
    },
    hasApprovers() {
      return Boolean(this.approvers.length);
    },
  },
  APPROVED_MESSAGE,
};
</script>

<template>
  <div data-qa-selector="approvals_summary_content">
    <strong>{{ message }}</strong>
    <template v-if="hasApprovers">
      <span>{{ s__('mrWidget|Approved by') }}</span>
      <user-avatar-list class="d-inline-block align-middle" :items="approvers" />
    </template>
  </div>
</template>
