<script>
import { GlButton, GlModal, GlModalDirective } from '@gitlab/ui';
import { escape } from 'lodash';
import { s__, __, sprintf } from '~/locale';

export default {
  components: {
    GlModal,
    GlButton,
  },
  directives: {
    'gl-modal': GlModalDirective,
  },
  props: {
    deleteWikiUrl: {
      type: String,
      required: true,
      default: '',
    },
    pageTitle: {
      type: String,
      required: true,
      default: '',
    },
    csrfToken: {
      type: String,
      required: true,
      default: '',
    },
  },
  computed: {
    title() {
      return sprintf(
        s__('WikiPageConfirmDelete|Delete page %{pageTitle}?'),
        {
          pageTitle: escape(this.pageTitle),
        },
        false,
      );
    },
    primaryProps() {
      return {
        text: this.$options.i18n.deletePageText,
        attributes: {
          variant: 'danger',
          'data-qa-selector': 'confirm_deletion_button',
          'data-testid': 'confirm_deletion_button',
        },
      };
    },
    cancelProps() {
      return {
        text: this.$options.i18n.cancelButtonText,
      };
    },
  },
  methods: {
    onSubmit() {
      window.onbeforeunload = null;
      this.$refs.form.submit();
    },
  },
  i18n: {
    deletePageText: s__('WikiPageConfirmDelete|Delete page'),
    modalBody: s__('WikiPageConfirmDelete|Are you sure you want to delete this page?'),
    cancelButtonText: __('Cancel'),
  },
  modal: {
    modalId: 'delete-wiki-modal',
  },
};
</script>

<template>
  <div class="d-inline-block">
    <gl-button
      v-gl-modal="$options.modal.modalId"
      category="secondary"
      variant="danger"
      data-qa-selector="delete_button"
    >
      {{ $options.i18n.deletePageText }}
    </gl-button>
    <gl-modal
      :title="title"
      :action-primary="primaryProps"
      :action-cancel="cancelProps"
      :modal-id="$options.modal.modalId"
      size="sm"
      @ok="onSubmit"
    >
      {{ $options.i18n.modalBody }}
      <form ref="form" :action="deleteWikiUrl" method="post" class="js-requires-input">
        <input ref="method" type="hidden" name="_method" value="delete" />
        <input :value="csrfToken" type="hidden" name="authenticity_token" />
      </form>
    </gl-modal>
  </div>
</template>
