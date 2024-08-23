<script>
// eslint-disable-next-line no-restricted-imports
import { mapState } from 'vuex';
import { GlEmptyState, GlLoadingIcon } from '@gitlab/ui';

import SubscriptionsList from '../components/subscriptions_list.vue';
import AddNamespaceButton from '../components/add_namespace_button.vue';

export default {
  name: 'SubscriptionsPage',
  components: {
    GlEmptyState,
    GlLoadingIcon,
    SubscriptionsList,
    AddNamespaceButton,
  },
  props: {
    hasSubscriptions: {
      type: Boolean,
      required: true,
    },
  },
  computed: {
    ...mapState(['subscriptionsLoading', 'subscriptionsError']),
  },
};
</script>

<template>
  <div>
    <h2 class="gl-mb-7 gl-text-center">{{ s__('JiraConnect|GitLab for Jira Configuration') }}</h2>

    <gl-loading-icon v-if="subscriptionsLoading" size="lg" />
    <div v-else-if="hasSubscriptions && !subscriptionsError">
      <div class="gl-mb-3 gl-flex gl-justify-end">
        <add-namespace-button />
      </div>

      <subscriptions-list />
    </div>
    <gl-empty-state
      v-else
      :title="s__('JiraConnect|No linked groups')"
      :description="
        s__(
          'JiraConnect|Groups are the GitLab groups and subgroups you link to this Jira instance.',
        )
      "
    >
      <template #actions>
        <add-namespace-button />
      </template>
    </gl-empty-state>
  </div>
</template>
