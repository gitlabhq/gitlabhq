<script>
import { GlSprintf, GlModal, GlLink } from '@gitlab/ui';
import { s__, __, sprintf } from '~/locale';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { subscribeWithLimitEnforce } from 'ee_else_ce/work_items/list/utils';
import namespaceSavedViewQuery from '~/work_items/graphql/namespace_saved_view.query.graphql';
import { ROUTES } from '~/work_items/constants';

export default {
  name: 'WorkItemsSavedViewsLimitWarningModal',
  components: {
    GlModal,
    GlSprintf,
    GlLink,
  },
  modal: {
    body: s__(
      'WorkItem|You have reached the maximum number of views in your list. If you add this view, the last view currently in your list will be removed (not deleted). %{linkStart}Learn more about view limits%{linkEnd}.',
    ),
    note: s__(
      'WorkItem|Note: removed views can be added back by going to %{boldStart}+ Add view %{arrow} Browse views%{boldEnd}.',
    ),
    actionPrimary: {
      text: s__('WorkItem|Add view'),
    },
    actionCancel: {
      text: __('Cancel'),
    },
  },
  inject: ['subscribedSavedViewLimit'],
  props: {
    show: {
      type: Boolean,
      required: true,
    },
    viewId: {
      type: String,
      required: false,
      default: null,
    },
    fullPath: {
      type: String,
      required: true,
    },
  },
  emits: ['hide'],
  data() {
    return {
      view: null,
    };
  },
  apollo: {
    view: {
      query: namespaceSavedViewQuery,
      variables() {
        return {
          fullPath: this.fullPath,
          id: this.viewId,
        };
      },
      skip() {
        return !this.viewId;
      },
      update(data) {
        return data?.namespace?.savedViews?.nodes[0];
      },
      error(e) {
        Sentry.captureException(e);
      },
    },
  },
  computed: {
    modalTitle() {
      if (this.view?.name) {
        return sprintf(s__('WorkItem|Add %{viewName} view?'), {
          viewName: this.view?.name,
        });
      }
      return '';
    },
  },
  methods: {
    async handleSubscriptionAtLimit() {
      try {
        await subscribeWithLimitEnforce({
          view: this.view,
          apolloClient: this.$apollo,
          namespacePath: this.fullPath,
          subscribedSavedViewLimit: this.subscribedSavedViewLimit,
        });

        const viewId = getIdFromGraphQLId(this.view.id).toString();
        this.$router.push({
          name: ROUTES.savedView,
          params: { view_id: viewId },
          query: undefined,
        });
      } catch (error) {
        Sentry.captureException(error);
      } finally {
        this.$emit('hide');
      }
    },
    handleHide() {
      if (this.$route.query.sv_limit_id) {
        this.$router.replace({ query: null });
      }
      this.$emit('hide');
    },
  },
};
</script>

<template>
  <gl-modal
    modal-id="saved-view-limit-warning"
    :aria-label="modalTitle"
    :title="modalTitle"
    :visible="show"
    :action-primary="$options.modal.actionPrimary"
    :action-cancel="$options.modal.actionCancel"
    body-class="!gl-pb-0"
    size="sm"
    no-focus-on-show
    @hide="handleHide"
    @primary="handleSubscriptionAtLimit"
  >
    <p>
      <gl-sprintf :message="$options.modal.body">
        <template #link="{ content }">
          <gl-link>{{ content }}</gl-link>
        </template>
      </gl-sprintf>
    </p>
    <p>
      <gl-sprintf :message="$options.modal.note">
        <template #bold="{ content }">
          <span class="gl-font-bold">
            <gl-sprintf :message="content">
              <template #arrow>&gt;</template>
            </gl-sprintf>
          </span>
        </template>
      </gl-sprintf>
    </p>
  </gl-modal>
</template>
