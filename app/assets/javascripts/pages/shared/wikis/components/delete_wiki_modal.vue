<script>
import { GlButton, GlIcon, GlDisclosureDropdownItem, GlModal, GlModalDirective } from '@gitlab/ui';
import { escape } from 'lodash';
import { s__, __, sprintf } from '~/locale';
import { isTemplate } from '../utils';

export default {
  components: {
    GlModal,
    GlButton,
    GlIcon,
    GlDisclosureDropdownItem,
  },
  directives: {
    'gl-modal': GlModalDirective,
  },
  inject: ['wikiUrl', 'pageHeading', 'csrfToken', 'pagePersisted'],
  props: {
    showAsDropdownItem: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    isTemplate,
    title() {
      let title = this.isTemplate
        ? this.$options.i18n.deleteTemplateTitle
        : this.$options.i18n.deletePageTitle;
      if (this.isCustomSidebar) {
        title = this.$options.i18n.deleteSidebarTitle;
      }
      return sprintf(title, { pageTitle: escape(this.pageHeading) }, false);
    },
    primaryProps() {
      let deleteText = this.deleteTemplateText;
      if (this.isCustomSidebar) deleteText = this.$options.i18n.modalFooterSidebarButtonText;

      return {
        text: deleteText,
        attributes: {
          variant: 'danger',
          'data-testid': 'confirm-deletion-button',
        },
      };
    },
    deleteTemplateText() {
      let buttonText = this.isTemplate
        ? this.$options.i18n.deleteTemplateText
        : this.$options.i18n.deletePageText;

      if (this.isCustomSidebar) buttonText = this.$options.i18n.deleteSidebarText;

      return buttonText;
    },
    modalBody() {
      let body = this.isTemplate
        ? this.$options.i18n.modalBodyTemplate
        : this.$options.i18n.modalBody;
      if (this.isCustomSidebar) body = this.$options.i18n.modalBodySidebar;

      return body;
    },
    cancelProps() {
      return {
        text: this.$options.i18n.cancelButtonText,
      };
    },
    listItem() {
      return {
        text: this.deleteTemplateText,
        extraAttrs: {
          class: '!gl-text-red-500',
          'data-testid': 'page-delete-button',
        },
      };
    },
    isCustomSidebar() {
      return this.wikiUrl.endsWith('_sidebar');
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
    deleteSidebarText: s__('WikiPageConfirmDelete|Delete custom sidebar'),
    modalBodySidebar: s__(
      'WikiPageConfirmDelete|Are you sure you want to delete the custom sidebar?',
    ),
    modalFooterSidebarButtonText: s__('WikiPageConfirmDelete|Delete'),
    deleteSidebarTitle: s__('WikiPageConfirmDelete|Delete custom sidebar?'),
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
  <div v-if="pagePersisted">
    <gl-disclosure-dropdown-item
      v-if="showAsDropdownItem"
      v-gl-modal="$options.modal.modalId"
      :item="listItem"
    >
      <template #list-item>
        <gl-icon name="remove" class="gl-mr-2" variant="danger" />
        {{ listItem.text }}
      </template>
    </gl-disclosure-dropdown-item>
    <gl-button
      v-else
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
      <form ref="form" :action="wikiUrl" method="post">
        <input ref="method" type="hidden" name="_method" value="delete" />
        <input :value="csrfToken" type="hidden" name="authenticity_token" />
      </form>
    </gl-modal>
  </div>
</template>
