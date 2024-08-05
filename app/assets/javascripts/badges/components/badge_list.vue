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
import { GROUP_BADGE, PROJECT_BADGE, INITIAL_PAGE, PAGE_SIZE } from '../constants';
import Badge from './badge.vue';

export default {
  PAGE_SIZE,
  INITIAL_PAGE,
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
  data() {
    return {
      currentPage: INITIAL_PAGE,
    };
  },
  computed: {
    ...mapState(['badges', 'isLoading', 'kind']),
    hasNoBadges() {
      return !this.isLoading && (!this.badges || !this.badges.length);
    },
    isGroupBadge() {
      return this.kind === GROUP_BADGE;
    },
    showPagination() {
      return this.badges.length > PAGE_SIZE;
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
          thClass: 'gl-text-right',
          tdClass: 'gl-text-right',
        },
      ];
    },
  },
  methods: {
    ...mapActions(['editBadge', 'updateBadgeInModal']),
    badgeKindText(item) {
      if (item.kind === PROJECT_BADGE) {
        return s__('Badges|Project Badge');
      }

      return s__('Badges|Group Badge');
    },
    canEditBadge(item) {
      return item.kind === this.kind;
    },
  },
};
</script>

<template>
  <div>
    <gl-loading-icon v-show="isLoading" size="md" />
    <div data-testid="badge-list-content">
      <gl-table
        :empty-text="emptyMessage"
        :fields="fields"
        :items="badges"
        :per-page="$options.PAGE_SIZE"
        :current-page="currentPage"
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
            class="table-action-buttons gl-flex gl-gap-2 gl-justify-end"
            data-testid="badge-actions"
          >
            <gl-button
              v-gl-tooltip
              v-gl-modal.edit-badge-modal
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

      <gl-pagination
        v-if="showPagination"
        v-model="currentPage"
        :per-page="$options.PAGE_SIZE"
        :total-items="badges.length"
        align="center"
        class="gl-mt-5"
      />
    </div>
  </div>
</template>
