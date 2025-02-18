<script>
import { GlLink, GlDrawer, GlButton, GlTooltipDirective, GlOutsideDirective } from '@gitlab/ui';
import { __ } from '~/locale';
import deleteWorkItemMutation from '~/work_items/graphql/delete_work_item.mutation.graphql';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { TYPE_EPIC, TYPE_ISSUE } from '~/issues/constants';
import {
  DETAIL_VIEW_QUERY_PARAM_NAME,
  INJECTION_LINK_CHILD_PREVENT_ROUTER_NAVIGATION,
} from '~/work_items/constants';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import { visitUrl, setUrlParams, updateHistory, removeParams } from '~/lib/utils/url_utility';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { makeDrawerItemFullPath, makeDrawerUrlParam, canRouterNav } from '../utils';

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
  mixins: [glFeatureFlagMixin()],
  inject: {
    preventRouterNav: {
      from: INJECTION_LINK_CHILD_PREVENT_ROUTER_NAVIGATION,
      default: false,
    },
    isGroup: {},
    fullPath: {},
  },
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
    newCommentTemplatePaths: {
      type: Array,
      required: false,
      default: () => [],
    },
  },
  data() {
    return {
      copyTooltipText: this.$options.i18n.copyTooltipText,
    };
  },
  computed: {
    activeItemFullPath() {
      return makeDrawerItemFullPath(this.activeItem, this.fullPath, this.issuableType);
    },
    modalIsGroup() {
      return this.issuableType.toLowerCase() === TYPE_EPIC;
    },
    headerReference() {
      const path = this.activeItemFullPath.substring(this.activeItemFullPath.lastIndexOf('/') + 1);
      return `${path}#${this.activeItem.iid}`;
    },
    issueAsWorkItem() {
      return (
        !this.isGroup &&
        this.glFeatures.workItemsViewPreference &&
        gon.current_user_use_work_items_view
      );
    },
  },
  watch: {
    activeItem: {
      deep: true,
      immediate: true,
      handler(newValue, oldValue) {
        if (newValue?.iid) {
          this.setDrawerParams();
          // focus on header link when drawer is updated
          this.$nextTick(() => {
            if (!oldValue || oldValue?.iid !== newValue?.iid) {
              this.focusOnHeaderLink();
            }
          });
        }
      },
    },
    open: {
      immediate: true,
      handler(newValue) {
        if (newValue) {
          // focus on header link when drawer is updated
          this.$nextTick(() => {
            this.focusOnHeaderLink();
          });
        }
      },
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
        this.$emit('workItemDeleted', { id: workItemId });
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
      const shouldRouterNav =
        !this.preventRouterNav &&
        this.$router &&
        canRouterNav({
          fullPath: this.fullPath,
          webUrl: workItem.webUrl,
          isGroup: this.isGroup,
          issueAsWorkItem: this.issueAsWorkItem,
        });

      if (shouldRouterNav) {
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
    setDrawerParams() {
      const params = makeDrawerUrlParam(this.activeItem, this.fullPath, this.issuableType);
      updateHistory({
        // we're using `show` to match the modal view parameter
        url: setUrlParams({ [DETAIL_VIEW_QUERY_PARAM_NAME]: params }),
      });
    },
    handleClose(isClickedOutside) {
      updateHistory({ url: removeParams([DETAIL_VIEW_QUERY_PARAM_NAME]) });

      if (!isClickedOutside) {
        document
          .getElementById(
            `listItem-${this.activeItemFullPath}/${getIdFromGraphQLId(this.activeItem.id)}`,
          )
          ?.focus();
      }

      this.$emit('close');
    },
    handleClickOutside(event) {
      for (const selector of this.$options.defaultExcludedSelectors) {
        const excludedElements = document.querySelectorAll(selector);
        for (const parent of excludedElements) {
          if (parent.contains(event.target)) {
            this.$emit('clicked-outside');
            return;
          }
        }
      }
      if (this.clickOutsideExcludeSelector) {
        const excludedElements = document.querySelectorAll(this.clickOutsideExcludeSelector);
        for (const parent of excludedElements) {
          if (parent.contains(event.target)) {
            this.$emit('clicked-outside');
            return;
          }
        }
      }
      this.handleClose(true);
    },
    focusOnHeaderLink() {
      this.$refs?.workItemUrl?.$el?.focus();
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
    'input[type="file"]',
    '.pika-single',
    '.atwho-container',
    '.item-title',
    '.tippy-content .gl-new-dropdown-panel',
    '#blocked-by-issues-modal',
    '#open-children-warning-modal',
    '#create-work-item-modal',
    '#work-item-confirm-delete',
    '.work-item-link-child',
    '.modal-content',
    '#create-merge-request-modal',
  ],
};
</script>

<template>
  <gl-drawer
    v-gl-outside="handleClickOutside"
    :open="open"
    :z-index="200"
    data-testid="work-item-drawer"
    header-sticky
    header-height="calc(var(--top-bar-height) + var(--performance-bar-height))"
    class="gl-w-full gl-leading-reset lg:gl-w-[480px] xl:gl-w-[768px] min-[1440px]:gl-w-[912px]"
    @close="handleClose"
    @opened="$emit('opened')"
  >
    <template #title>
      <div class="gl-text gl-flex gl-w-full gl-items-center gl-gap-x-2 xl:gl-px-4">
        <gl-link
          ref="workItemUrl"
          data-testid="work-item-drawer-ref-link"
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
        :new-comment-template-paths="newCommentTemplatePaths"
        is-drawer
        class="work-item-drawer !gl-pt-0 xl:!gl-px-6"
        @deleteWorkItem="deleteWorkItem"
        @workItemTypeChanged="$emit('workItemTypeChanged', $event)"
        v-on="$listeners"
      />
    </template>
  </gl-drawer>
</template>
