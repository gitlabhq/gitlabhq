<script>
import { GlModal } from '@gitlab/ui';
import csrf from '~/lib/utils/csrf';

export default {
  components: {
    GlModal,
  },
  props: {
    modalAttributes: {
      type: Object,
      required: true,
    },
    path: {
      type: String,
      required: true,
    },
    method: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      isDismissed: false,
    };
  },
  mounted() {
    this.openModal();
  },
  methods: {
    openModal() {
      this.$refs.modal.show();
    },
    submitModal() {
      this.$refs.form.requestSubmit();
    },
    dismiss() {
      this.isDismissed = true;
    },
  },
  csrf,
};
</script>

<template>
  <gl-modal
    v-if="!isDismissed"
    ref="modal"
    v-bind="modalAttributes"
    @primary="submitModal"
    @canceled="dismiss"
  >
    <form ref="form" :action="path" method="post">
      <!-- Rails workaround for <form method="delete" />
      https://github.com/rails/rails/blob/master/actionview/app/assets/javascripts/rails-ujs/features/method.coffee
      -->
      <input type="hidden" name="_method" :value="method" />
      <input type="hidden" name="authenticity_token" :value="$options.csrf.token" />
      <div>{{ modalAttributes.message }}</div>
    </form>
  </gl-modal>
</template>
