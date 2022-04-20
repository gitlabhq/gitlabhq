<script>
import { uniqueId } from 'lodash';
import { GlButton, GlModal, GlModalDirective, GlSprintf } from '@gitlab/ui';
import { __ } from '~/locale';
import csrf from '~/lib/utils/csrf';

export default {
  components: {
    GlButton,
    GlModal,
    GlSprintf,
  },
  directives: {
    GlModal: GlModalDirective,
  },
  inject: ['path', 'name'],
  data() {
    return {
      modalId: uniqueId('remove-topic-avatar-'),
    };
  },
  methods: {
    deleteApplication() {
      this.$refs.deleteForm.submit();
    },
  },
  i18n: {
    remove: __('Remove avatar'),
    title: __('Remove topic avatar'),
    body: __('Topic avatar for %{name} will be removed. This cannot be undone.'),
  },
  modal: {
    actionPrimary: {
      text: __('Remove'),
      attributes: {
        variant: 'danger',
      },
    },
    actionSecondary: {
      text: __('Cancel'),
      attributes: {
        variant: 'default',
      },
    },
  },
  csrf,
};
</script>
<template>
  <div>
    <gl-button v-gl-modal="modalId" variant="danger" category="secondary" class="gl-mt-2">{{
      $options.i18n.remove
    }}</gl-button>
    <gl-modal
      :title="$options.i18n.title"
      :action-primary="$options.modal.actionPrimary"
      :action-secondary="$options.modal.actionSecondary"
      :modal-id="modalId"
      size="sm"
      @primary="deleteApplication"
      ><gl-sprintf :message="$options.i18n.body"
        ><template #name>{{ name }}</template></gl-sprintf
      >
      <form ref="deleteForm" method="post" :action="path">
        <input type="hidden" name="_method" value="delete" />
        <input type="hidden" name="authenticity_token" :value="$options.csrf.token" />
      </form>
    </gl-modal>
  </div>
</template>
