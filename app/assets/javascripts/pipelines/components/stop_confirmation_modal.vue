<script>
  import modal from '~/vue_shared/components/modal.vue';
  import { s__, sprintf } from '~/locale';
  import eventHub from '../event_hub';

  export default {
    components: {
      modal,
    },
    data() {
      return {
        id: '',
        callback: () => {},
      };
    },
    computed: {
      title() {
        return sprintf(s__('Pipeline|Stop pipeline #%{id}?'), {
          id: `'${this.id}'`,
        }, false);
      },
      text() {
        return sprintf(s__('Pipeline|You’re about to stop pipeline %{id}.'), {
          id: `<strong>#${this.id}</strong>`,
        }, false);
      },
      primaryButtonLabel() {
        return s__('Pipeline|Stop pipeline');
      },
    },
    created() {
      eventHub.$on('actionConfirmationModal', this.updateModal);
    },
    beforeDestroy() {
      eventHub.$off('actionConfirmationModal', this.updateModal);
    },
    methods: {
      updateModal(action) {
        this.id = action.id;
        this.callback = action.callback;
      },
      onSubmit() {
        this.callback();
      },
    },
  };
</script>

<template>
  <modal
    id="stop-confirmation-modal"
    :title="title"
    :text="text"
    kind="danger"
    :primary-button-label="primaryButtonLabel"
    @submit="onSubmit"
  >
    <template
      slot="body"
      slot-scope="props"
    >
      <p v-html="props.text"></p>
    </template>
  </modal>
</template>
