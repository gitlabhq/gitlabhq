<script>
import { GlModal, GlAlert } from '@gitlab/ui';
import { uniqueId } from 'lodash';
import SafeHtml from '~/vue_shared/directives/safe_html';
import csrf from '~/lib/utils/csrf';
import eventHub, { EVENT_OPEN_CONFIRM_MODAL } from './confirm_modal_eventhub';
import DomElementListener from './dom_element_listener.vue';

export default {
  components: {
    GlAlert,
    GlModal,
    DomElementListener,
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
    eventHub.$on(EVENT_OPEN_CONFIRM_MODAL, this.onOpenEvent);
  },
  destroyed() {
    eventHub.$off(EVENT_OPEN_CONFIRM_MODAL, this.onOpenEvent);
  },
  methods: {
    onButtonPress(e) {
      const element = e.currentTarget;

      if (!element.dataset.path) {
        return;
      }

      const modalAttributes = element.dataset.modalAttributes
        ? JSON.parse(element.dataset.modalAttributes)
        : {};

      this.onOpenEvent({
        path: element.dataset.path,
        method: element.dataset.method,
        modalAttributes,
      });
    },
    onOpenEvent({ path, method, modalAttributes }) {
      this.path = path;
      this.method = method;
      this.modalAttributes = modalAttributes;
      this.openModal();
    },
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
  <dom-element-listener :selector="selector" @click.prevent="onButtonPress">
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
        <gl-alert
          v-if="modalAttributes.errorAlertMessage"
          class="gl-mb-3"
          variant="danger"
          :dismissible="false"
          >{{ modalAttributes.errorAlertMessage }}</gl-alert
        >
        <div v-if="modalAttributes.messageHtml" v-safe-html="modalAttributes.messageHtml"></div>
        <div v-else>{{ modalAttributes.message }}</div>
      </form>
    </gl-modal>
  </dom-element-listener>
</template>
