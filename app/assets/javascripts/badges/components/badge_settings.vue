<script>
import { mapState, mapActions } from 'vuex';
import createFlash from '~/flash';
import { s__ } from '~/locale';
import GlModal from '~/vue_shared/components/gl_modal.vue';
import Badge from './badge.vue';
import BadgeForm from './badge_form.vue';
import BadgeList from './badge_list.vue';

export default {
  name: 'BadgeSettings',
  components: {
    Badge,
    BadgeForm,
    BadgeList,
    GlModal,
  },
  computed: {
    ...mapState(['badgeInModal', 'isEditing']),
    deleteModalText() {
      return s__(
        'Badges|You are going to delete this badge. Deleted badges <strong>cannot</strong> be restored.',
      );
    },
  },
  methods: {
    ...mapActions(['deleteBadge']),
    onSubmitModal() {
      this.deleteBadge(this.badgeInModal)
        .then(() => {
          createFlash(s__('Badges|The badge was deleted.'), 'notice');
        })
        .catch(error => {
          createFlash(s__('Badges|Deleting the badge failed, please try again.'));
          throw error;
        });
    },
  },
};
</script>

<template>
  <div class="badge-settings">
    <gl-modal
      id="delete-badge-modal"
      :header-title-text="s__('Badges|Delete badge?')"
      footer-primary-button-variant="danger"
      :footer-primary-button-text="s__('Badges|Delete badge')"
      @submit="onSubmitModal">
      <div class="well">
        <badge
          :image-url="badgeInModal ? badgeInModal.renderedImageUrl : ''"
          :link-url="badgeInModal ? badgeInModal.renderedLinkUrl : ''"
        />
      </div>
      <p v-html="deleteModalText"></p>
    </gl-modal>

    <badge-form
      v-show="isEditing"
      :is-editing="true"
    />

    <badge-form
      v-show="!isEditing"
      :is-editing="false"
    />
    <badge-list v-show="!isEditing" />
  </div>
</template>
