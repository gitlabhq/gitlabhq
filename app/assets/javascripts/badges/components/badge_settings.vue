<script>
import { GlButton, GlCard, GlModal, GlIcon, GlSprintf } from '@gitlab/ui';
// eslint-disable-next-line no-restricted-imports
import { mapState, mapActions } from 'vuex';
import { createAlert, VARIANT_INFO } from '~/alert';
import { __, s__ } from '~/locale';
import Badge from './badge.vue';
import BadgeForm from './badge_form.vue';
import BadgeList from './badge_list.vue';

export default {
  name: 'BadgeSettings',
  components: {
    Badge,
    BadgeForm,
    BadgeList,
    GlButton,
    GlCard,
    GlModal,
    GlIcon,
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
  data() {
    return {
      addFormVisible: false,
    };
  },
  computed: {
    ...mapState(['badges', 'badgeInModal', 'isEditing']),
    saveProps() {
      return {
        text: __('Save changes'),
        attributes: { category: 'primary', variant: 'confirm' },
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
  methods: {
    ...mapActions(['deleteBadge']),
    showAddForm() {
      this.addFormVisible = !this.addFormVisible;
    },
    closeAddForm() {
      this.addFormVisible = false;
    },
    onSubmitEditModal() {
      this.$refs.editForm.onSubmit();
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
  <div class="badge-settings">
    <gl-card
      class="gl-new-card"
      header-class="gl-new-card-header"
      body-class="gl-new-card-body gl-px-0"
    >
      <template #header>
        <div class="gl-new-card-title-wrapper">
          <h3 class="gl-new-card-title">{{ $options.i18n.title }}</h3>
          <span class="gl-new-card-count">
            <gl-icon name="labels" class="gl-mr-2" />
            {{ badges.length }}
          </span>
        </div>
        <div class="gl-new-card-actions">
          <gl-button
            v-if="!addFormVisible"
            size="small"
            data-testid="show-badge-add-form"
            @click="showAddForm"
            >{{ $options.i18n.addButton }}</gl-button
          >
        </div>
      </template>

      <div v-if="addFormVisible" class="gl-new-card-add-form gl-m-5">
        <h4 class="gl-mt-0">{{ $options.i18n.addFormTitle }}</h4>
        <badge-form :is-editing="false" @close-add-form="closeAddForm" />
      </div>

      <badge-list />
    </gl-card>

    <gl-modal
      modal-id="edit-badge-modal"
      :title="s__('Badges|Edit badge')"
      :action-primary="saveProps"
      :action-cancel="cancelProps"
      @primary="onSubmitEditModal"
    >
      <badge-form ref="editForm" :is-editing="true" :in-modal="true" data-testid="edit-badge" />
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
  </div>
</template>
