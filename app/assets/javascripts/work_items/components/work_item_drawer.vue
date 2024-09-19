<script>
import { GlLink, GlDrawer, GlButton, GlTooltipDirective, GlOutsideDirective } from '@gitlab/ui';
import { escapeRegExp } from 'lodash';
import { __ } from '~/locale';
import deleteWorkItemMutation from '~/work_items/graphql/delete_work_item.mutation.graphql';
import { TYPE_EPIC, TYPE_ISSUE } from '~/issues/constants';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import { visitUrl } from '~/lib/utils/url_utility';

export default {
  name: 'WorkItemDrawer',
  directives: {
    GlTooltip: GlTooltipDirective,
    GlOutside: GlOutsideDirective,
  },
  components: {
    GlLink,
    GlDrawer,
    GlButton,
    WorkItemDetail: () => import('~/work_items/components/work_item_detail.vue'),
  },
  inject: ['fullPath'],
  inheritAttrs: false,
  props: {
    open: {
      type: Boolean,
      required: true,
    },
    activeItem: {
      type: Object,
      required: false,
      default: () => ({}),
    },
    issuableType: {
      type: String,
      required: false,
      default: TYPE_ISSUE,
    },
    clickOutsideExcludeSelector: {
      type: String,
      required: false,
      default: null,
    },
  },
  data() {
    return {
      copyTooltipText: this.$options.i18n.copyTooltipText,
    };
  },
  computed: {
    activeItemFullPath() {
      if (this.activeItem?.fullPath) {
        return this.activeItem.fullPath;
      }
      const delimiter = this.issuableType === TYPE_EPIC ? '&' : '#';
      if (!this.activeItem.referencePath) {
        return undefined;
      }
      return this.activeItem.referencePath.split(delimiter)[0];
    },
    modalIsGroup() {
      return this.issuableType.toLowerCase() === TYPE_EPIC;
    },
    headerReference() {
      const path = this.activeItemFullPath.substring(this.activeItemFullPath.lastIndexOf('/') + 1);
      return `${path}#${this.activeItem.iid}`;
    },
  },
  methods: {
    async deleteWorkItem({ workItemId }) {
      try {
        const { data } = await this.$apollo.mutate({
          mutation: deleteWorkItemMutation,
          variables: { input: { id: workItemId } },
        });
        if (data.workItemDelete.errors?.length) {
          throw new Error(data.workItemDelete.errors[0]);
        }
        this.$emit('workItemDeleted');
      } catch (error) {
        this.$emit('deleteWorkItemError');
        Sentry.captureException(error);
      }
    },
    redirectToWorkItem(e) {
      const workItem = this.activeItem;
      if (e.metaKey || e.ctrlKey) {
        return;
      }
      e.preventDefault();
      const escapedFullPath = escapeRegExp(this.fullPath);
      // eslint-disable-next-line no-useless-escape
      const regex = new RegExp(`groups\/${escapedFullPath}\/-\/(work_items|epics)\/\\d+`);
      const isWorkItemPath = regex.test(workItem.webUrl);

      if (isWorkItemPath) {
        this.$router.push({
          name: 'workItem',
          params: {
            iid: workItem.iid,
          },
        });
      } else {
        visitUrl(workItem.webUrl);
      }
    },
    handleCopyToClipboard() {
      this.copyTooltipText = this.$options.i18n.copiedTooltipText;
      setTimeout(() => {
        this.copyTooltipText = this.$options.i18n.copyTooltipText;
      }, 2000);
    },
    handleClickOutside(event) {
      for (const selector of this.$options.defaultExcludedSelectors) {
        const excludedElements = document.querySelectorAll(selector);
        for (const parent of excludedElements) {
          if (parent.contains(event.target)) {
            return;
          }
        }
      }
      if (this.clickOutsideExcludeSelector) {
        const excludedElements = document.querySelectorAll(this.clickOutsideExcludeSelector);
        for (const parent of excludedElements) {
          if (parent.contains(event.target)) {
            return;
          }
        }
      }
      this.$emit('close');
    },
  },
  i18n: {
    copyTooltipText: __('Copy item URL'),
    copiedTooltipText: __('Copied'),
    openTooltipText: __('Open in full page'),
  },
  defaultExcludedSelectors: [
    '#confirmationModal',
    '#create-timelog-modal',
    '#set-time-estimate-modal',
    '[id^="insert-comment-template-modal"]',
    '.pika-single',
    '.atwho-container',
    '.tippy-content .gl-new-dropdown-panel',
  ],
};
</script>

<template>
  <gl-drawer
    v-gl-outside="handleClickOutside"
    :open="open"
    data-testid="work-item-drawer"
    header-sticky
    header-height="calc(var(--top-bar-height) + var(--performance-bar-height))"
    class="gl-w-full gl-leading-reset lg:gl-w-[480px] xl:gl-w-[768px] min-[1440px]:gl-w-[912px]"
    @close="$emit('close')"
  >
    <template #title>
      <div class="gl-text gl-flex gl-w-full gl-items-center gl-gap-x-2 xl:gl-px-4">
        <gl-link
          :href="activeItem.webUrl"
          class="gl-text-sm gl-font-bold gl-text-default"
          @click="redirectToWorkItem"
        >
          {{ headerReference }}
        </gl-link>
        <gl-button
          v-gl-tooltip
          data-testid="work-item-drawer-copy-button"
          :title="copyTooltipText"
          category="tertiary"
          class="gl-text-secondary"
          icon="link"
          size="small"
          :aria-label="$options.i18n.copyTooltipText"
          :data-clipboard-text="activeItem.webUrl"
          @click="handleCopyToClipboard"
        />
        <gl-button
          v-gl-tooltip
          data-testid="work-item-drawer-link-button"
          :href="activeItem.webUrl"
          :title="$options.i18n.openTooltipText"
          category="tertiary"
          class="gl-text-secondary"
          icon="maximize"
          size="small"
          :aria-label="$options.i18n.openTooltipText"
          @click="redirectToWorkItem"
        />
      </div>
    </template>
    <template #default>
      <work-item-detail
        :key="activeItem.iid"
        :work-item-iid="activeItem.iid"
        :modal-work-item-full-path="activeItemFullPath"
        :modal-is-group="modalIsGroup"
        is-drawer
        class="work-item-drawer !gl-pt-0 xl:!gl-px-6"
        @deleteWorkItem="deleteWorkItem"
        v-on="$listeners"
      />
    </template>
  </gl-drawer>
</template>
