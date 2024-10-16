<script>
import { GlModal, GlSprintf } from '@gitlab/ui';
// eslint-disable-next-line no-restricted-imports
import { mapState, mapActions } from 'vuex';
import { createAlert, VARIANT_INFO } from '~/alert';
import { __, s__ } from '~/locale';
import CrudComponent from '~/vue_shared/components/crud_component.vue';
import { INITIAL_PAGE } from '../constants';
import Badge from './badge.vue';
import BadgeForm from './badge_form.vue';
import BadgeList from './badge_list.vue';

export default {
  name: 'BadgeSettings',
  components: {
    CrudComponent,
    Badge,
    BadgeForm,
    BadgeList,
    GlModal,
    GlSprintf,
  },
  i18n: {
    title: s__('Badges|Your badges'),
    addButton: s__('Badges|Add badge'),
    addFormTitle: s__('Badges|Add new badge'),
    deleteModalText: s__(
      'Badges|If you delete this badge, you %{strongStart}cannot%{strongEnd} restore it.',
    ),
  },
  computed: {
    ...mapState(['pagination', 'badgeInModal', 'isEditing', 'isSaving']),
    saveProps() {
      return {
        text: __('Save changes'),
        attributes: { category: 'primary', variant: 'confirm', loading: this.isSaving },
      };
    },
    deleteProps() {
      return {
        text: __('Delete badge'),
        attributes: { category: 'primary', variant: 'danger' },
      };
    },
    cancelProps() {
      return {
        text: __('Cancel'),
      };
    },
  },
  created() {
    this.loadBadges({ page: INITIAL_PAGE });
  },
  methods: {
    ...mapActions(['loadBadges', 'deleteBadge', 'stopEditing']),
    closeAddForm() {
      this.$refs.badgesCrud.hideForm();
    },
    onSubmitEditModal() {
      this.$refs.editForm.$el.dispatchEvent(new CustomEvent('submit', { cancelable: true }));
    },
    onSubmitDeleteModal() {
      this.deleteBadge(this.badgeInModal)
        .then(() => {
          createAlert({
            message: s__('Badges|The badge was deleted.'),
            variant: VARIANT_INFO,
          });
        })
        .catch((error) => {
          createAlert({
            message: s__('Badges|Failed to delete the badge. Try again.'),
          });
          throw error;
        });
    },
  },
};
</script>

<template>
  <crud-component
    ref="badgesCrud"
    :title="$options.i18n.title"
    icon="labels"
    :count="pagination.total"
    :toggle-text="$options.i18n.addFormTitle"
    data-testid="badge-settings"
  >
    <template #form>
      <h4 class="gl-mt-0">{{ $options.i18n.addFormTitle }}</h4>
      <badge-form :is-editing="false" @close-add-form="closeAddForm" />
    </template>

    <badge-list />

    <gl-modal
      modal-id="edit-badge-modal"
      :visible="isEditing"
      :title="s__('Badges|Edit badge')"
      :action-primary="saveProps"
      :action-cancel="cancelProps"
      @primary.prevent="onSubmitEditModal"
      @hidden="stopEditing"
    >
      <badge-form ref="editForm" :is-editing="true" data-testid="edit-badge" />
    </gl-modal>

    <gl-modal
      modal-id="delete-badge-modal"
      :title="s__('Badges|Delete badge?')"
      :action-primary="deleteProps"
      :action-cancel="cancelProps"
      @primary="onSubmitDeleteModal"
    >
      <div class="well">
        <badge
          :image-url="badgeInModal ? badgeInModal.renderedImageUrl : ''"
          :link-url="badgeInModal ? badgeInModal.renderedLinkUrl : ''"
        />
      </div>
      <p>
        <gl-sprintf :message="$options.i18n.deleteModalText">
          <template #strong="{ content }">
            <strong>{{ content }}</strong>
          </template>
        </gl-sprintf>
      </p>
    </gl-modal>
  </crud-component>
</template>
