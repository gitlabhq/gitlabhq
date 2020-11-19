<script>
import { GlModal, GlSafeHtmlDirective as SafeHtml } from '@gitlab/ui';
import { uniqueId } from 'lodash';
import csrf from '~/lib/utils/csrf';

export default {
  components: {
    GlModal,
  },
  directives: {
    SafeHtml,
  },
  props: {
    selector: {
      type: String,
      required: true,
    },
    handleSubmit: {
      type: Function,
      required: false,
      default: null,
    },
  },
  data() {
    return {
      modalId: uniqueId('confirm-modal-'),
      path: '',
      method: '',
      modalAttributes: {},
    };
  },
  mounted() {
    document.querySelectorAll(this.selector).forEach(button => {
      button.addEventListener('click', e => {
        e.preventDefault();

        this.path = button.dataset.path;
        this.method = button.dataset.method;
        this.modalAttributes = JSON.parse(button.dataset.modalAttributes);
        this.openModal();
      });
    });
  },
  methods: {
    openModal() {
      this.$refs.modal.show();
    },
    closeModal() {
      this.$refs.modal.hide();
    },
    submitModal() {
      if (this.handleSubmit) {
        this.handleSubmit(this.path);
      } else {
        this.$refs.form.submit();
      }
    },
  },
  csrf,
};
</script>

<template>
  <gl-modal
    ref="modal"
    :modal-id="modalId"
    v-bind="modalAttributes"
    @primary="submitModal"
    @cancel="closeModal"
  >
    <form ref="form" :action="path" method="post">
      <!-- Rails workaround for <form method="delete" />
      https://github.com/rails/rails/blob/master/actionview/app/assets/javascripts/rails-ujs/features/method.coffee
      -->
      <input type="hidden" name="_method" :value="method" />
      <input type="hidden" name="authenticity_token" :value="$options.csrf.token" />
      <div v-if="modalAttributes.messageHtml" v-safe-html="modalAttributes.messageHtml"></div>
      <div v-else>{{ modalAttributes.message }}</div>
    </form>
  </gl-modal>
</template>
