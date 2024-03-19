<script>
import { GlButton, GlModal, GlModalDirective } from '@gitlab/ui';
import { escape } from 'lodash';
import { s__, __, sprintf } from '~/locale';
import { isTemplate } from '../utils';

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
    },
    pageTitle: {
      type: String,
      required: true,
    },
    csrfToken: {
      type: String,
      required: true,
    },
  },
  computed: {
    isTemplate,
    title() {
      return sprintf(
        this.isTemplate
          ? this.$options.i18n.deleteTemplateTitle
          : this.$options.i18n.deletePageTitle,
        {
          pageTitle: escape(this.pageTitle),
        },
        false,
      );
    },
    primaryProps() {
      return {
        text: this.isTemplate
          ? this.$options.i18n.deleteTemplateText
          : this.$options.i18n.deletePageText,
        attributes: {
          variant: 'danger',
          'data-testid': 'confirm-deletion-button',
        },
      };
    },
    deleteTemplateText() {
      return this.isTemplate
        ? this.$options.i18n.deleteTemplateText
        : this.$options.i18n.deletePageText;
    },
    modalBody() {
      return this.isTemplate ? this.$options.i18n.modalBodyTemplate : this.$options.i18n.modalBody;
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
    deletePageTitle: s__('WikiPageConfirmDelete|Delete page "%{pageTitle}"?'),
    deleteTemplateTitle: s__('WikiPageConfirmDelete|Delete template "%{pageTitle}"?'),
    deletePageText: s__('WikiPageConfirmDelete|Delete page'),
    deleteTemplateText: s__('WikiPageConfirmDelete|Delete template'),
    modalBody: s__('WikiPageConfirmDelete|Are you sure you want to delete this page?'),
    modalBodyTemplate: s__('WikiPageConfirmDelete|Are you sure you want to delete this template?'),
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
      data-testid="delete-button"
    >
      {{ deleteTemplateText }}
    </gl-button>
    <gl-modal
      :title="title"
      :action-primary="primaryProps"
      :action-cancel="cancelProps"
      :modal-id="$options.modal.modalId"
      size="sm"
      @ok="onSubmit"
    >
      {{ modalBody }}
      <form ref="form" :action="deleteWikiUrl" method="post" class="js-requires-input">
        <input ref="method" type="hidden" name="_method" value="delete" />
        <input :value="csrfToken" type="hidden" name="authenticity_token" />
      </form>
    </gl-modal>
  </div>
</template>
