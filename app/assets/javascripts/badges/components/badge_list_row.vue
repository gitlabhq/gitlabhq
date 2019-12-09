<script>
import { mapActions, mapState } from 'vuex';
import { GlLoadingIcon } from '@gitlab/ui';
import { s__ } from '~/locale';
import Icon from '~/vue_shared/components/icon.vue';
import { PROJECT_BADGE } from '../constants';
import Badge from './badge.vue';

export default {
  name: 'BadgeListRow',
  components: {
    Badge,
    Icon,
    GlLoadingIcon,
  },
  props: {
    badge: {
      type: Object,
      required: true,
    },
  },
  computed: {
    ...mapState(['kind']),
    badgeKindText() {
      if (this.badge.kind === PROJECT_BADGE) {
        return s__('Badges|Project Badge');
      }

      return s__('Badges|Group Badge');
    },
    canEditBadge() {
      return this.badge.kind === this.kind;
    },
  },
  methods: {
    ...mapActions(['editBadge', 'updateBadgeInModal']),
  },
};
</script>

<template>
  <div class="gl-responsive-table-row-layout gl-responsive-table-row">
    <badge
      :image-url="badge.renderedImageUrl"
      :link-url="badge.renderedLinkUrl"
      class="table-section section-30"
    />
    <div class="table-section section-30">
      <label class="label-bold str-truncated mb-0">{{ badge.name }}</label>
      <span class="badge badge-pill">{{ badgeKindText }}</span>
    </div>
    <span class="table-section section-30 str-truncated">{{ badge.linkUrl }}</span>
    <div class="table-section section-10 table-button-footer">
      <div v-if="canEditBadge" class="table-action-buttons">
        <button
          :disabled="badge.isDeleting"
          class="btn btn-default append-right-8"
          type="button"
          @click="editBadge(badge)"
        >
          <icon :size="16" :aria-label="__('Edit')" name="pencil" />
        </button>
        <button
          :disabled="badge.isDeleting"
          class="btn btn-danger"
          type="button"
          data-toggle="modal"
          data-target="#delete-badge-modal"
          @click="updateBadgeInModal(badge)"
        >
          <icon :size="16" :aria-label="__('Delete')" name="remove" />
        </button>
        <gl-loading-icon v-show="badge.isDeleting" :inline="true" />
      </div>
    </div>
  </div>
</template>
