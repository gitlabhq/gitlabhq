<script>
import { GlLoadingIcon, GlSkeletonLoader } from '@gitlab/ui';
import autoMergeMixin from 'ee_else_ce/vue_merge_request_widget/mixins/auto_merge';
import autoMergeEnabledQuery from 'ee_else_ce/vue_merge_request_widget/queries/states/auto_merge_enabled.query.graphql';
import createFlash from '~/flash';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { __ } from '~/locale';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { AUTO_MERGE_STRATEGIES } from '../../constants';
import eventHub from '../../event_hub';
import mergeRequestQueryVariablesMixin from '../../mixins/merge_request_query_variables';
import MrWidgetAuthor from '../mr_widget_author.vue';
import statusIcon from '../mr_widget_status_icon.vue';

export default {
  name: 'MRWidgetAutoMergeEnabled',
  apollo: {
    state: {
      query: autoMergeEnabledQuery,
      skip() {
        return !this.glFeatures.mergeRequestWidgetGraphql;
      },
      variables() {
        return this.mergeRequestQueryVariables;
      },
      update: (data) => data.project?.mergeRequest,
    },
  },
  components: {
    MrWidgetAuthor,
    statusIcon,
    GlLoadingIcon,
    GlSkeletonLoader,
  },
  mixins: [autoMergeMixin, glFeatureFlagMixin(), mergeRequestQueryVariablesMixin],
  props: {
    mr: {
      type: Object,
      required: true,
      default: () => ({}),
    },
    service: {
      type: Object,
      required: true,
      default: () => ({}),
    },
  },
  data() {
    return {
      state: {},
      isCancellingAutoMerge: false,
      isRemovingSourceBranch: false,
    };
  },
  computed: {
    loading() {
      return (
        this.glFeatures.mergeRequestWidgetGraphql &&
        this.$apollo.queries.state.loading &&
        Object.keys(this.state).length === 0
      );
    },
    mergeUser() {
      if (this.glFeatures.mergeRequestWidgetGraphql) {
        return this.state.mergeUser;
      }

      return this.mr.setToAutoMergeBy;
    },
    targetBranch() {
      return (this.glFeatures.mergeRequestWidgetGraphql ? this.state : this.mr).targetBranch;
    },
    shouldRemoveSourceBranch() {
      if (!this.glFeatures.mergeRequestWidgetGraphql) return this.mr.shouldRemoveSourceBranch;

      if (!this.state.shouldRemoveSourceBranch) return false;

      return this.state.shouldRemoveSourceBranch || this.state.forceRemoveSourceBranch;
    },
    autoMergeStrategy() {
      return (this.glFeatures.mergeRequestWidgetGraphql ? this.state : this.mr).autoMergeStrategy;
    },
    canRemoveSourceBranch() {
      const { currentUserId } = this.mr;
      const mergeUserId = this.glFeatures.mergeRequestWidgetGraphql
        ? getIdFromGraphQLId(this.state.mergeUser?.id)
        : this.mr.mergeUserId;
      const canRemoveSourceBranch = this.glFeatures.mergeRequestWidgetGraphql
        ? this.state.userPermissions.removeSourceBranch
        : this.mr.canRemoveSourceBranch;

      return (
        !this.shouldRemoveSourceBranch && canRemoveSourceBranch && mergeUserId === currentUserId
      );
    },
  },
  methods: {
    cancelAutomaticMerge() {
      this.isCancellingAutoMerge = true;
      this.service
        .cancelAutomaticMerge()
        .then((res) => res.data)
        .then((data) => {
          if (this.glFeatures.mergeRequestWidgetGraphql) {
            eventHub.$emit('MRWidgetUpdateRequested');
          } else {
            eventHub.$emit('UpdateWidgetData', data);
          }
        })
        .catch(() => {
          this.isCancellingAutoMerge = false;
          createFlash({
            message: __('Something went wrong. Please try again.'),
          });
        });
    },
    removeSourceBranch() {
      const options = {
        sha: this.mr.sha,
        auto_merge_strategy: this.autoMergeStrategy,
        should_remove_source_branch: true,
      };

      this.isRemovingSourceBranch = true;
      this.service
        .merge(options)
        .then((res) => res.data)
        .then((data) => {
          if (AUTO_MERGE_STRATEGIES.includes(data.status)) {
            eventHub.$emit('MRWidgetUpdateRequested');
          }
        })
        .then(() => {
          if (this.glFeatures.mergeRequestWidgetGraphql) {
            this.$apollo.queries.state.refetch();
          }
        })
        .catch(() => {
          this.isRemovingSourceBranch = false;
          createFlash({
            message: __('Something went wrong. Please try again.'),
          });
        });
    },
  },
};
</script>
<template>
  <div class="mr-widget-body media">
    <div v-if="loading" class="gl-w-full mr-conflict-loader">
      <gl-skeleton-loader :width="334" :height="30">
        <rect x="0" y="3" width="24" height="24" rx="4" />
        <rect x="32" y="7" width="150" height="16" rx="4" />
        <rect x="190" y="7" width="144" height="16" rx="4" />
      </gl-skeleton-loader>
    </div>
    <template v-else>
      <status-icon status="success" />
      <div class="media-body">
        <h4 class="gl-display-flex">
          <span class="gl-mr-3">
            <span class="js-status-text-before-author" data-testid="beforeStatusText">{{
              statusTextBeforeAuthor
            }}</span>
            <mr-widget-author :author="mergeUser" />
            <span class="js-status-text-after-author" data-testid="afterStatusText">{{
              statusTextAfterAuthor
            }}</span>
          </span>
          <a
            v-if="mr.canCancelAutomaticMerge"
            :disabled="isCancellingAutoMerge"
            role="button"
            href="#"
            class="btn btn-sm btn-default js-cancel-auto-merge"
            data-qa-selector="cancel_auto_merge_button"
            data-testid="cancelAutomaticMergeButton"
            @click.prevent="cancelAutomaticMerge"
          >
            <gl-loading-icon v-if="isCancellingAutoMerge" size="sm" inline class="gl-mr-1" />
            {{ cancelButtonText }}
          </a>
        </h4>
        <section class="mr-info-list">
          <p>
            {{ s__('mrWidget|The changes will be merged into') }}
            <a :href="mr.targetBranchPath" class="label-branch">{{ targetBranch }}</a>
          </p>
          <p v-if="shouldRemoveSourceBranch">
            {{ s__('mrWidget|The source branch will be deleted') }}
          </p>
          <p v-else class="gl-display-flex">
            <span class="gl-mr-3">{{ s__('mrWidget|The source branch will not be deleted') }}</span>
            <a
              v-if="canRemoveSourceBranch"
              :disabled="isRemovingSourceBranch"
              role="button"
              class="btn btn-sm btn-default js-remove-source-branch"
              href="#"
              data-testid="removeSourceBranchButton"
              @click.prevent="removeSourceBranch"
            >
              <gl-loading-icon v-if="isRemovingSourceBranch" size="sm" inline class="gl-mr-1" />
              {{ s__('mrWidget|Delete source branch') }}
            </a>
          </p>
        </section>
      </div>
    </template>
  </div>
</template>
