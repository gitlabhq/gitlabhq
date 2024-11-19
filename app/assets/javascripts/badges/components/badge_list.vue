<script>
import {
  GlBadge,
  GlLoadingIcon,
  GlTable,
  GlTooltipDirective,
  GlPagination,
  GlButton,
  GlModalDirective,
} from '@gitlab/ui';
// eslint-disable-next-line no-restricted-imports
import { mapActions, mapState } from 'vuex';
import { __, s__ } from '~/locale';
import { GROUP_BADGE, PROJECT_BADGE } from '../constants';
import Badge from './badge.vue';

export default {
  name: 'BadgeList',
  components: {
    Badge,
    GlBadge,
    GlLoadingIcon,
    GlTable,
    GlPagination,
    GlButton,
  },
  directives: {
    GlModal: GlModalDirective,
    GlTooltip: GlTooltipDirective,
  },
  i18n: {
    edit: __('Edit'),
    delete: __('Delete'),
    emptyGroupMessage: s__('Badges|This group has no badges. Add an existing badge or create one.'),
    emptyProjectMessage: s__('Badges|This project has no badges. Start by adding a new badge.'),
  },
  computed: {
    ...mapState(['badges', 'pagination', 'isLoading', 'kind']),
    isGroupBadge() {
      return this.kind === GROUP_BADGE;
    },
    showPagination() {
      return Boolean(this.pagination.nextPage) || Boolean(this.pagination.previousPage);
    },
    emptyMessage() {
      return this.isGroupBadge
        ? this.$options.i18n.emptyGroupMessage
        : this.$options.i18n.emptyProjectMessage;
    },
    fields() {
      return [
        {
          key: 'name',
          label: __('Name'),
          tdClass: '!gl-align-middle',
        },
        {
          key: 'badge',
          label: __('Badge'),
          tdClass: '!gl-align-middle',
        },
        {
          key: 'url',
          label: __('URL'),
          tdClass: '!gl-align-middle',
        },
        {
          key: 'actions',
          label: __('Actions'),
          thAlignRight: true,
          tdClass: 'gl-text-right',
        },
      ];
    },
  },
  methods: {
    ...mapActions(['editBadge', 'updateBadgeInModal', 'loadBadges']),
    badgeKindText(item) {
      if (item.kind === PROJECT_BADGE) {
        return s__('Badges|Project Badge');
      }

      return s__('Badges|Group Badge');
    },
    canEditBadge(item) {
      return item.kind === this.kind;
    },
    onPageChange(page) {
      // GlPagination still emits events on click when buttons are disabled
      if (!page || page > this.pagination.totalPages) {
        return;
      }

      this.loadBadges({ page });
    },
  },
};
</script>

<template>
  <div data-testid="badge-list-content">
    <gl-table
      :empty-text="emptyMessage"
      :fields="fields"
      :items="badges"
      stacked="md"
      show-empty
      class="b-table-fixed"
      data-testid="badge-list"
    >
      <template #cell(name)="{ item }">
        <label v-gl-tooltip class="label-bold str-truncated mb-0" :title="item.name">{{
          item.name
        }}</label>
        <gl-badge>{{ badgeKindText(item) }}</gl-badge>
      </template>

      <template #cell(badge)="{ item }">
        <div class="overflow-hidden">
          <badge :image-url="item.renderedImageUrl" :link-url="item.renderedLinkUrl" />
        </div>
      </template>

      <template #cell(url)="{ item }">
        <span v-gl-tooltip :title="item.linkUrl" class="str-truncated">
          {{ item.linkUrl }}
        </span>
      </template>

      <template #cell(actions)="{ item }">
        <div
          v-if="canEditBadge(item)"
          class="table-action-buttons gl-flex gl-justify-end gl-gap-2"
          data-testid="badge-actions"
        >
          <gl-button
            v-gl-tooltip
            :disabled="item.isDeleting"
            category="tertiary"
            icon="pencil"
            size="medium"
            :title="$options.i18n.edit"
            :aria-label="$options.i18n.edit"
            data-testid="edit-badge-button"
            @click="editBadge(item)"
          />
          <gl-button
            v-gl-tooltip
            v-gl-modal.delete-badge-modal
            :disabled="item.isDeleting"
            category="tertiary"
            icon="remove"
            size="medium"
            :title="$options.i18n.delete"
            :aria-label="$options.i18n.delete"
            data-testid="delete-badge"
            @click="updateBadgeInModal(item)"
          />
          <gl-loading-icon v-show="item.isDeleting" size="sm" :inline="true" />
        </div>
      </template>
    </gl-table>

    <gl-loading-icon v-if="isLoading" size="md" class="gl-pb-5" />
    <gl-pagination
      v-if="!isLoading && showPagination"
      :value="pagination.page"
      :per-page="pagination.perPage"
      :total-items="pagination.total"
      align="center"
      class="gl-mt-5"
      @input="onPageChange"
    />
  </div>
</template>
