<script>
import { s__ } from '~/locale';
import eventHub from './eventHub';

export default {
  computed: {
    modalId() {
      return 'set-status-modal';
    },
  },
  mounted() {
    eventHub.$on('openModal', this.openModal);
  },
  methods: {
    onSubmit() {
      console.log('Do something');
    },
    openModal() {
      this.$root.$emit('bv::show::modal', this.modalId)
    },
  },
};
</script>

<template>
  <gl-ui-modal
    :title="s__('SetStatusModal|Set a Status')"
    :ok-title="s__('SetStatusModal|Set status')"
    :modal-id="modalId"
    :ok-only="true"
    title-tag="h4"
    @ok="onSubmit"
  >
    <form
      ref="form"
      action="deleteWikiUrl"
      method="post"
      class="js-requires-input"
    >
      <input
        ref="method"
        type="hidden"
        name="_method"
        value="delete"
      />
      <input
        value="csrfToken"
        type="hidden"
        name="authenticity_token"
      />
      <input
        value=""
        type="text"
        name="emoji"
      />
    </form>
  </gl-ui-modal>
</template>
