<script>
/* eslint-disable vue/no-v-html */
import { GlModal } from '@gitlab/ui';
import { sprintf } from '~/locale';

export default {
  components: {
    GlModal,
  },
  props: {
    title: {
      type: String,
      required: true,
    },
    content: {
      type: String,
      required: true,
    },
    action: {
      type: String,
      required: true,
    },
    url: {
      type: String,
      required: true,
    },
    username: {
      type: String,
      required: true,
    },
    csrfToken: {
      type: String,
      required: true,
    },
    method: {
      type: String,
      required: false,
      default: 'put',
    },
  },
  computed: {
    modalTitle() {
      return sprintf(this.title, { username: this.username });
    },
  },
  methods: {
    show() {
      this.$refs.modal.show();
    },
    submit() {
      this.$refs.form.submit();
    },
  },
};
</script>
<template>
  <gl-modal
    ref="modal"
    modal-id="user-operation-modal"
    :title="modalTitle"
    ok-variant="warning"
    :ok-title="action"
    @ok="submit"
  >
    <form ref="form" :action="url" method="post">
      <span v-html="content"></span>
      <input ref="method" type="hidden" name="_method" :value="method" />
      <input :value="csrfToken" type="hidden" name="authenticity_token" />
    </form>
  </gl-modal>
</template>
