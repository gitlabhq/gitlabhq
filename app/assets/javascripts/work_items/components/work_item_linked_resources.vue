<script>
import { GlIcon, GlLink } from '@gitlab/ui';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import { s__ } from '~/locale';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import CrudComponent from '~/vue_shared/components/crud_component.vue';
import workItemLinkedResourcesQuery from '../graphql/work_item_linked_resources.query.graphql';
import workItemLinkedResourcesUpdatedSubscription from '../graphql/work_item_linked_resources.subscription.graphql';
import { findLinkedResourcesWidget } from '../utils';

export default {
  name: 'WorkItemLinkedResources',
  components: {
    CrudComponent,
    GlIcon,
    GlLink,
  },
  mixins: [glFeatureFlagsMixin()],
  props: {
    fullPath: {
      type: String,
      required: true,
    },
    workItemIid: {
      type: String,
      required: true,
    },
  },
  emits: ['error'],
  data() {
    return {
      workItem: {},
    };
  },
  apollo: {
    workItem: {
      query: workItemLinkedResourcesQuery,
      variables() {
        return {
          fullPath: this.fullPath,
          iid: this.workItemIid,
          useWorkItemFeatures: Boolean(this.glFeatures?.workItemFeaturesField),
        };
      },
      skip() {
        return !this.workItemIid;
      },
      update(data) {
        return data?.namespace?.workItem ?? {};
      },
      error(error) {
        Sentry.captureException(error);
        this.$emit(
          'error',
          s__('WorkItem|Something went wrong when fetching resources. Please try again.'),
        );
      },
      // Quick actions like `/zoom` change the work item server-side. Listening for the update
      // keeps the widget live without a refetch, which would fan out across every query sharing
      // the `widgets` and `features` cache fields.
      subscribeToMore: {
        document: workItemLinkedResourcesUpdatedSubscription,
        variables() {
          return {
            id: this.workItem.id,
            useWorkItemFeatures: Boolean(this.glFeatures?.workItemFeaturesField),
          };
        },
        skip() {
          return !this.workItem?.id;
        },
      },
    },
  },
  computed: {
    linkedResources() {
      return findLinkedResourcesWidget(this.workItem)?.linkedResources?.nodes ?? [];
    },
  },
};
</script>

<template>
  <crud-component
    v-if="linkedResources.length"
    anchor-id="resources"
    :count="linkedResources.length"
    is-collapsible
    persist-collapsed-state
    :title="s__('WorkItem|Resources')"
  >
    <template #default>
      <span
        v-for="resource in linkedResources"
        :key="resource.url"
        class="gl-border gl-inline-flex gl-rounded-base gl-bg-default gl-px-3 gl-py-2"
      >
        <gl-link
          class="gl-inline-flex gl-items-center gl-gap-3 gl-font-semibold gl-text-default hover:gl-text-default focus-visible:gl-text-default"
          :href="resource.url"
        >
          <gl-icon name="brand-zoom" />
          {{ s__('WorkItem|Zoom link') }}
        </gl-link>
      </span>
    </template>
  </crud-component>
</template>
