<script>
import { GlModal } from '@gitlab/ui';
import { TYPE_EPIC } from '~/issues/constants';
import csrf from '~/lib/utils/csrf';
import { capitalizeFirstCharacter } from '~/lib/utils/text_utility';
import { __, sprintf } from '~/locale';

export default {
  actionCancel: { text: __('Cancel') },
  csrf,
  components: {
    GlModal,
  },
  props: {
    issuePath: {
      type: String,
      required: false,
      default: '',
    },
    issueType: {
      type: String,
      required: true,
    },
    modalId: {
      type: String,
      required: true,
    },
    title: {
      type: String,
      required: true,
    },
  },
  computed: {
    actionPrimary() {
      return {
        attributes: {
          variant: 'danger',
          'data-testid': 'confirm-delete-issue-button',
        },
        text: this.title,
      };
    },
    bodyText() {
      return this.issueType.toLowerCase() === TYPE_EPIC
        ? __('Delete this epic and release all child items?')
        : sprintf(__('%{issuableType} will be removed! Are you sure?'), {
            issuableType: capitalizeFirstCharacter(this.issueType),
          });
    },
  },
  methods: {
    submitForm() {
      this.$emit('delete');
      this.$refs.form.submit();
    },
  },
};
</script>

<template>
  <gl-modal
    :action-cancel="$options.actionCancel"
    :action-primary="actionPrimary"
    :modal-id="modalId"
    size="sm"
    :title="title"
    @primary="submitForm"
  >
    <form ref="form" :action="issuePath" method="post">
      <input type="hidden" name="_method" value="delete" />
      <input type="hidden" name="authenticity_token" :value="$options.csrf.token" />
      <input type="hidden" name="destroy_confirm" value="true" />
      {{ bodyText }}
    </form>
  </gl-modal>
</template>
