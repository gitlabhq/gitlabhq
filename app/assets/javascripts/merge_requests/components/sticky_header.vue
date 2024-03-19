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
    projectPath: { default: null },
    sourceProjectPath: { default: null },
    title: { default: '' },
    isFluidLayout: { default: false },
    blocksMerge: { default: false },
  },
  props: {
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
      class="issue-sticky-header merge-request-sticky-header gl-fixed gl-bg-white gl-display-none gl-md-display-flex gl-flex-direction-column gl-justify-content-end gl-border-b"
      :class="{ 'gl-visibility-hidden': !isStickyHeaderVisible }"
    >
      <div
        class="issue-sticky-header-text gl-display-flex gl-flex-direction-column gl-align-items-center gl-mx-auto gl-w-full"
        :class="{ 'container-limited': !isFluidLayout }"
      >
        <div class="gl-w-full gl-display-flex gl-align-items-baseline">
          <status-badge
            class="gl-align-self-center gl-mr-3"
            :issuable-type="$options.TYPE_MERGE_REQUEST"
            :state="badgeState.state"
          />
          <a
            v-safe-html:[$options.safeHtmlConfig]="titleHtml"
            href="#top"
            class="gl-display-none gl-lg-display-block gl-font-weight-bold gl-overflow-hidden gl-white-space-nowrap gl-text-overflow-ellipsis gl-my-0 gl-mr-4 gl-text-black-normal"
          ></a>
          <div class="gl-display-flex gl-align-items-baseline">
            <gl-sprintf :message="__('%{source} %{copyButton} into %{target}')">
              <template #copyButton>
                <clipboard-button
                  v-gl-tooltip.bottom.html="copySourceBranchTooltip"
                  :text="getNoteableData.source_branch"
                  size="small"
                  category="tertiary"
                  class="gl-m-0! gl-mx-1! js-source-branch-copy gl-align-self-center"
                />
              </template>
              <template #source>
                <gl-link
                  :title="getNoteableData.source_branch"
                  :href="getNoteableData.source_branch_path"
                  class="gl-text-blue-500! gl-font-monospace gl-bg-blue-50 gl-rounded-base gl-font-sm gl-px-2 gl-text-truncate gl-max-w-26"
                  data-testid="source-branch"
                >
                  <span
                    v-if="isForked"
                    v-gl-tooltip
                    class="gl-vertical-align-middle gl-mr-n2"
                    :title="__('The source project is a fork')"
                  >
                    <gl-icon name="fork" :size="12" class="gl-ml-1" />
                  </span>
                  {{ sourceBranch }}
                </gl-link>
              </template>
              <template #target>
                <gl-link
                  :title="getNoteableData.target_branch"
                  :href="getNoteableData.target_branch_path"
                  class="gl-text-blue-500! gl-font-monospace gl-bg-blue-50 gl-rounded-base gl-font-sm gl-px-2 gl-text-truncate gl-max-w-26 gl-ml-2"
                >
                  {{ getNoteableData.target_branch }}
                </gl-link>
              </template>
            </gl-sprintf>
          </div>
        </div>
        <div class="gl-w-full gl-display-flex">
          <ul
            class="merge-request-tabs nav-tabs nav nav-links gl-display-flex gl-flex-nowrap gl-m-0 gl-p-0 gl-border-b-0"
          >
            <li
              v-for="(tab, index) in tabs"
              :key="tab[0]"
              :class="{ active: activeTab === tab[0] }"
            >
              <gl-link
                :href="tab[2]"
                :data-action="tab[0]"
                class="gl-outline-0! gl-py-4!"
                @click="visitTab"
              >
                {{ tab[1] }}
                <gl-badge variant="muted" size="sm">
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
          <div class="gl-display-none gl-lg-display-flex gl-align-items-center gl-ml-auto">
            <discussion-counter :blocks-merge="blocksMerge" hide-options />
            <div
              v-if="isSignedIn"
              :class="{ 'gl-display-flex gl-gap-3': isNotificationsTodosButtons }"
            >
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
