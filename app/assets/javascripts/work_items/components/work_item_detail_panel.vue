<script>
import { GlLink, GlButton, GlTooltipDirective } from '@gitlab/ui';
import { MountingPortal } from 'portal-vue';
import { __ } from '~/locale';
import deleteWorkItemMutation from '~/work_items/graphql/delete_work_item.mutation.graphql';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { TYPE_ISSUE } from '~/issues/constants';
import {
  DETAIL_VIEW_QUERY_PARAM_NAME,
  DETAIL_VIEW_DESIGN_VERSION_PARAM_NAME,
  WORK_ITEM_TYPE_ROUTE_WORK_ITEM,
} from '~/work_items/constants';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import { visitUrl, setUrlParams, updateHistory, removeParams } from '~/lib/utils/url_utility';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { makeDetailPanelItemFullPath, makeDetailPanelUrlParam, canRouterNav } from '../utils';
import WorkItemMetadataProvider from './work_item_metadata_provider.vue';

export default {
  name: 'WorkItemDetailPanel',
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  components: {
    GlLink,
    GlButton,
    MountingPortal,
    WorkItemDetail: () => import('ee_else_ce/work_items/components/work_item_detail.vue'),
    WorkItemMetadataProvider,
  },
  mixins: [glFeatureFlagMixin()],
  inject: {
    preventRouterNav: {
      default: false,
    },
    isGroup: {},
    fullPath: {},
  },
  provide() {
    return {
      viewContext: this.viewContext,
    };
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
    isBoard: {
      type: Boolean,
      required: false,
      default: false,
    },
    viewContext: {
      type: String,
      required: true,
    },
  },
  emits: ['work-item-deleted', 'close', 'work-item-updated', 'workItemTypeChanged'],
  data() {
    return {
      copyTooltipText: this.$options.i18n.copyTooltipText,
      isWaitingForMutation: false,
    };
  },
  computed: {
    activeItemFullPath() {
      return makeDetailPanelItemFullPath(this.activeItem, this.fullPath, this.issuableType);
    },
    headerReference() {
      const path = this.activeItemFullPath.substring(this.activeItemFullPath.lastIndexOf('/') + 1);
      return `${path}#${this.activeItem.iid}`;
    },
  },
  watch: {
    activeItem: {
      deep: true,
      immediate: true,
      handler(newValue, oldValue) {
        if (newValue?.iid) {
          this.setDetailPanelParams();
          // focus on header link when detail-panel is updated
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
          // focus on header link when detail-panel is updated
          this.$nextTick(() => {
            this.focusOnHeaderLink();
          });
        }
      },
    },
  },
  mounted() {
    document.addEventListener('keydown', this.handleKeydown);
  },
  beforeDestroy() {
    document.removeEventListener('keydown', this.handleKeydown);
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
        this.$emit('work-item-deleted', { id: workItemId });
      } catch (error) {
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
        !this.isBoard &&
        this.$router &&
        canRouterNav({
          fullPath: this.fullPath,
          webUrl: workItem.webUrl, // eslint-disable-line local-rules/no-web-url
          isGroup: this.isGroup,
          issueAsWorkItem: !this.isGroup,
        });

      if (shouldRouterNav) {
        this.$router.push({
          name: 'workItem',
          params: {
            iid: workItem.iid,
            type: WORK_ITEM_TYPE_ROUTE_WORK_ITEM,
          },
        });
      } else {
        visitUrl(workItem.webUrl); // eslint-disable-line local-rules/no-web-url
      }
    },
    handleCopyToClipboard() {
      this.copyTooltipText = this.$options.i18n.copiedTooltipText;
      setTimeout(() => {
        this.copyTooltipText = this.$options.i18n.copyTooltipText;
      }, 2000);
    },
    setDetailPanelParams() {
      const params = makeDetailPanelUrlParam(this.activeItem, this.fullPath, this.issuableType);
      updateHistory({
        // we're using `show` to match the modal view parameter
        url: setUrlParams({ [DETAIL_VIEW_QUERY_PARAM_NAME]: params }),
      });
    },
    handleClose(isClickedOutside, bypassPendingRequests = false) {
      const { queryManager } = this.$apollo.provider.clients.defaultClient;
      // We only need this check when the user is on a board and the mutation is pending.
      this.isWaitingForMutation =
        this.isBoard &&
        window.pendingApolloRequests - queryManager.inFlightLinkObservables.size > 0;

      /* Do not close when a modal is open, or when the user is focused in an editor/input.
       */
      if (
        (this.isWaitingForMutation && !bypassPendingRequests) ||
        document.body.classList.contains('modal-open') ||
        document.body.classList.contains('image-lightbox-open') ||
        document.activeElement?.closest('.js-editor') != null ||
        document.activeElement.classList.contains('gl-form-input')
      ) {
        return;
      }

      updateHistory({
        url: removeParams([DETAIL_VIEW_QUERY_PARAM_NAME, DETAIL_VIEW_DESIGN_VERSION_PARAM_NAME]),
      });

      if (!isClickedOutside) {
        document
          .getElementById(
            `listItem-${this.activeItemFullPath}/${getIdFromGraphQLId(this.activeItem.id)}`,
          )
          ?.focus();
      }

      this.$emit('close');
    },
    focusOnHeaderLink() {
      this.$refs?.workItemUrl?.$el?.focus();
    },
    handleWorkItemUpdated(e) {
      this.$emit('work-item-updated', e);

      // Force to close the detail-panel after 100ms even if requests are still pending
      // to not let UI hanging.
      if (this.isWaitingForMutation) {
        setTimeout(() => {
          this.handleClose(false, true);
        }, 100);
      }
    },
    handleKeydown({ key }) {
      if (key === 'Escape' && this.open) {
        this.handleClose();
      }
    },
  },
  i18n: {
    copyTooltipText: __('Copy item URL'),
    copiedTooltipText: __('Copied'),
    openTooltipText: __('Open in full page'),
    closePanelText: __('Close panel'),
  },
};
</script>

<template>
  <mounting-portal v-if="open" mount-to="#contextual-panel-portal" append>
    <div
      data-testid="work-item-detail-panel"
      class="work-item-detail-panel gl-pt-4 gl-leading-reset"
    >
      <div class="work-item-detail-panel-header">
        <div class="gl-flex gl-grow gl-items-center gl-gap-2">
          <!-- eslint-disable local-rules/vue-no-web-url -->
          <gl-link
            ref="workItemUrl"
            data-testid="work-item-detail-panel-ref-link"
            :href="activeItem.webUrl"
            class="gl-text-sm gl-font-bold gl-text-default"
            @click="redirectToWorkItem"
          >
            {{ headerReference }}
          </gl-link>
          <gl-button
            v-gl-tooltip.bottom
            data-testid="work-item-detail-panel-copy-button"
            :title="copyTooltipText"
            category="tertiary"
            icon="link"
            size="small"
            :aria-label="$options.i18n.copyTooltipText"
            :data-clipboard-text="activeItem.webUrl"
            @click="handleCopyToClipboard"
          />
        </div>
        <gl-button
          v-gl-tooltip.bottom
          data-testid="work-item-detail-panel-link-button"
          :href="activeItem.webUrl"
          :title="$options.i18n.openTooltipText"
          category="tertiary"
          icon="maximize"
          size="small"
          :aria-label="$options.i18n.openTooltipText"
          @click="redirectToWorkItem"
        />
        <!-- eslint-enable local-rules/vue-no-web-url -->
        <gl-button
          v-gl-tooltip.bottom
          class="gl-detail-panel-close-button"
          category="tertiary"
          icon="close"
          size="small"
          :aria-label="$options.i18n.closePanelText"
          :title="$options.i18n.closePanelText"
          @click="handleClose"
        />
      </div>
      <work-item-metadata-provider :full-path="activeItemFullPath">
        <!-- eslint-disable vue/custom-event-name-casing, vue/v-on-event-hyphenation-->
        <work-item-detail
          :key="activeItem.iid"
          :work-item-iid="activeItem.iid"
          :work-item-full-path="activeItemFullPath"
          :is-board="isBoard"
          is-detail-panel
          class="js-dynamic-panel-inner work-item-detail-panel-content !gl-pt-0"
          @deleteWorkItem="deleteWorkItem"
          @work-item-updated="handleWorkItemUpdated"
          @workItemTypeChanged="$emit('workItemTypeChanged', $event)"
          v-on="$listeners"
        />
        <!-- eslint-enable vue/custom-event-name-casing, vue/v-on-event-hyphenation -->
      </work-item-metadata-provider>
    </div>
  </mounting-portal>
</template>
