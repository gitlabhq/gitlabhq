<script>
import { GlModal, GlSprintf } from '@gitlab/ui';
import { __ } from '~/locale';
import csrf from '~/lib/utils/csrf';

export default {
  components: {
    GlModal,
    GlSprintf,
  },
  data() {
    return {
      name: '',
      path: '',
      buttons: [],
    };
  },
  mounted() {
    this.buttons = document.querySelectorAll('.js-application-delete-button');

    this.buttons.forEach((button) => button.addEventListener('click', this.buttonEvent));
  },
  destroy() {
    this.buttons.forEach((button) => button.removeEventListener('click', this.buttonEvent));
  },
  methods: {
    buttonEvent(e) {
      e.preventDefault();
      this.show(e.currentTarget.dataset);
    },
    show(dataset) {
      const { name, path } = dataset;

      this.name = name;
      this.path = path;

      this.$refs.deleteModal.show();
    },
    deleteApplication() {
      this.$refs.deleteForm.submit();
    },
  },
  i18n: {
    destroy: __('Destroy'),
    title: __('Confirm destroy application'),
    body: __('Are you sure that you want to destroy %{application}'),
  },
  modal: {
    actionPrimary: {
      text: __('Destroy'),
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
  <gl-modal
    ref="deleteModal"
    :title="$options.i18n.title"
    :action-primary="$options.modal.actionPrimary"
    :action-secondary="$options.modal.actionSecondary"
    modal-id="delete-application-modal"
    size="sm"
    @primary="deleteApplication"
    ><gl-sprintf :message="$options.i18n.body">
      <template #application>
        <strong>{{ name }}</strong>
      </template></gl-sprintf
    >
    <form ref="deleteForm" method="post" :action="path">
      <input type="hidden" name="_method" value="delete" />
      <input type="hidden" name="authenticity_token" :value="$options.csrf.token" />
    </form>
  </gl-modal>
</template>
