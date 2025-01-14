<script>
import {
  GlIntersectionObserver,
  GlLink,
  GlSprintf,
  GlBadge,
  GlIcon,
  GlTooltipDirective,
} from '@gitlab/ui';
// eslint-disable-next-line no-restricted-imports
import { mapGetters, mapState } from 'vuex';
import { __ } from '~/locale';
import SafeHtml from '~/vue_shared/directives/safe_html';
import { shouldDisableShortcuts } from '~/behaviors/shortcuts/shortcuts_toggle';
import { sanitize } from '~/lib/dompurify';
import { TYPENAME_MERGE_REQUEST } from '~/graphql_shared/constants';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { isLoggedIn } from '~/lib/utils/common_utils';
import StatusBadge from '~/issuable/components/status_badge.vue';
import ImportedBadge from '~/vue_shared/components/imported_badge.vue';
import { TYPE_MERGE_REQUEST } from '~/issues/constants';
import DiscussionCounter from '~/notes/components/discussion_counter.vue';
import TodoWidget from '~/sidebar/components/todo_toggle/sidebar_todo_widget.vue';
import SubscriptionsWidget from '~/sidebar/components/subscriptions/sidebar_subscriptions_widget.vue';
import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';
import titleSubscription from '../queries/title.subscription.graphql';
import { badgeState } from './merge_request_header.vue';

export default {
  TYPE_MERGE_REQUEST,
  apollo: {
    $subscribe: {
      // eslint-disable-next-line @gitlab/vue-no-undef-apollo-properties
      title: {
        query() {
          return titleSubscription;
        },
        variables() {
          return {
            issuableId: this.issuableId,
          };
        },
        skip() {
          return !this.issuableId;
        },
        result({ data: { mergeRequestMergeStatusUpdated } }) {
          if (mergeRequestMergeStatusUpdated) {
            this.titleHtml = mergeRequestMergeStatusUpdated.titleHtml;
          }
        },
      },
    },
  },
  components: {
    GlIntersectionObserver,
    GlLink,
    GlSprintf,
    GlBadge,
    GlIcon,
    DiscussionCounter,
    StatusBadge,
    ImportedBadge,
    TodoWidget,
    SubscriptionsWidget,
    ClipboardButton,
  },
  directives: {
    SafeHtml,
    GlTooltip: GlTooltipDirective,
  },
  mixins: [glFeatureFlagsMixin()],
  inject: {
    defaultBranchName: { default: '' },
    projectPath: { default: null },
    sourceProjectPath: { default: null },
    title: { default: '' },
    isFluidLayout: { default: false },
    blocksMerge: { default: false },
  },
  props: {
    isImported: {
      type: Boolean,
      required: false,
      default: false,
    },
    tabs: {
      type: Array,
      required: true,
    },
  },
  data() {
    return {
      isStickyHeaderVisible: false,
      discussionCounter: 0,
      titleHtml: this.title,
    };
  },
  computed: {
    ...mapGetters(['getNoteableData', 'discussionTabCounter']),
    ...mapState({
      activeTab: (state) => state.page.activeTab,
      doneFetchingBatchDiscussions: (state) => state.notes.doneFetchingBatchDiscussions,
    }),
    badgeState() {
      return badgeState;
    },
    issuableId() {
      return convertToGraphQLId(TYPENAME_MERGE_REQUEST, this.getNoteableData.id);
    },
    issuableIid() {
      return `${this.getNoteableData.iid}`;
    },
    isSignedIn() {
      return isLoggedIn();
    },
    isNotificationsTodosButtons() {
      return this.glFeatures.notificationsTodosButtons;
    },
    isForked() {
      return this.projectPath !== this.sourceProjectPath;
    },
    sourceBranch() {
      if (this.isForked) {
        return `${this.sourceProjectPath}:${this.getNoteableData.source_branch}`;
      }

      return this.getNoteableData.source_branch;
    },
    copySourceBranchTooltip() {
      const description = __('Copy branch name');
      return shouldDisableShortcuts()
        ? description
        : sanitize(`${description} <kbd class="flat gl-ml-1" aria-hidden=true>b</kbd>`);
    },
    shouldShowTargetCopyButton() {
      return this.getNoteableData.target_branch !== this.defaultBranchName;
    },
  },
  watch: {
    discussionTabCounter(val) {
      if (this.doneFetchingBatchDiscussions) {
        this.discussionCounter = val;
      }
    },
  },
  methods: {
    setStickyHeaderVisible(val) {
      this.isStickyHeaderVisible = val;
    },
    visitTab(e) {
      window.mrTabs?.clickTab(e);
    },
  },
  safeHtmlConfig: {
    ADD_TAGS: ['gl-emoji'],
  },
};
</script>

<template>
  <gl-intersection-observer
    class="gl-relative -gl-top-5"
    @appear="setStickyHeaderVisible(false)"
    @disappear="setStickyHeaderVisible(true)"
  >
    <div
      class="issue-sticky-header merge-request-sticky-header gl-border-b gl-fixed gl-hidden gl-flex-col gl-justify-end gl-bg-default md:gl-flex"
      :class="{ 'gl-invisible': !isStickyHeaderVisible }"
    >
      <div
        class="issue-sticky-header-text gl-mx-auto gl-flex gl-w-full gl-flex-col gl-items-center"
        :class="{ 'container-limited': !isFluidLayout }"
      >
        <div class="gl-flex gl-w-full gl-items-center gl-gap-2">
          <status-badge :issuable-type="$options.TYPE_MERGE_REQUEST" :state="badgeState.state" />
          <imported-badge v-if="isImported" :importable-type="$options.TYPE_MERGE_REQUEST" />
          <a
            v-safe-html:[$options.safeHtmlConfig]="titleHtml"
            href="#top"
            class="gl-my-0 gl-ml-1 gl-mr-2 gl-hidden gl-overflow-hidden gl-text-ellipsis gl-whitespace-nowrap gl-font-bold gl-text-default lg:gl-block"
          ></a>
          <div class="gl-flex gl-items-center">
            <gl-sprintf :message="__('%{source} %{copyButton} into %{target} %{targetCopyButton}')">
              <template #copyButton>
                <clipboard-button
                  tooltip-placement="bottom"
                  :title="copySourceBranchTooltip"
                  :text="getNoteableData.source_branch"
                  size="small"
                  category="tertiary"
                  class="js-source-branch-copy gl-mx-1"
                />
              </template>
              <template #source>
                <gl-link
                  :title="getNoteableData.source_branch"
                  :href="getNoteableData.source_branch_path"
                  class="ref-container gl-mt-2 gl-max-w-26 gl-truncate gl-rounded-base gl-px-2 gl-text-sm gl-font-monospace"
                  data-testid="source-branch"
                >
                  <span
                    v-if="isForked"
                    v-gl-tooltip
                    class="-gl-mr-2 gl-align-middle"
                    :title="__('The source project is a fork')"
                  >
                    <gl-icon name="fork" :size="12" class="gl-ml-1" />
                  </span>
                  {{ sourceBranch }}
                </gl-link>
              </template>
              <template #targetCopyButton>
                <clipboard-button
                  v-if="shouldShowTargetCopyButton"
                  tooltip-placement="bottom"
                  :title="__('Copy branch name')"
                  :text="getNoteableData.target_branch"
                  size="small"
                  category="tertiary"
                  class="gl-mx-1"
                />
              </template>
              <template #target>
                <gl-link
                  :title="getNoteableData.target_branch"
                  :href="getNoteableData.target_branch_path"
                  class="ref-container gl-ml-2 gl-mt-2 gl-max-w-26 gl-truncate gl-rounded-base gl-px-2 gl-text-sm gl-font-monospace"
                >
                  {{ getNoteableData.target_branch }}
                </gl-link>
              </template>
            </gl-sprintf>
          </div>
        </div>
        <div class="gl-flex gl-w-full">
          <ul
            class="merge-request-tabs nav-tabs nav nav-links gl-m-0 gl-flex gl-flex-nowrap gl-border-b-0 gl-p-0"
          >
            <li
              v-for="(tab, index) in tabs"
              :key="tab[0]"
              :class="{ active: activeTab === tab[0] }"
            >
              <gl-link :href="tab[2]" :data-action="tab[0]" class="!gl-py-4" @click="visitTab">
                {{ tab[1] }}
                <gl-badge variant="muted">
                  <template v-if="index === 0 && discussionCounter !== 0">
                    {{ discussionCounter }}
                  </template>
                  <template v-else>
                    {{ tab[3] }}
                  </template>
                </gl-badge>
              </gl-link>
            </li>
          </ul>
          <div class="gl-ml-auto gl-hidden gl-items-center lg:gl-flex">
            <discussion-counter :blocks-merge="blocksMerge" hide-options />
            <div v-if="isSignedIn" :class="{ 'gl-flex gl-gap-3': isNotificationsTodosButtons }">
              <todo-widget
                :issuable-id="issuableId"
                :issuable-iid="issuableIid"
                :full-path="projectPath"
                issuable-type="merge_request"
              />
              <subscriptions-widget
                v-if="isNotificationsTodosButtons"
                :iid="issuableIid"
                :full-path="projectPath"
                issuable-type="merge_request"
              />
            </div>
          </div>
        </div>
      </div>
    </div>
  </gl-intersection-observer>
</template>
