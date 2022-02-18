<script>
import { GlEmptyState } from '@gitlab/ui';
import SubscriptionsList from '../components/subscriptions_list.vue';
import AddNamespaceButton from '../components/add_namespace_button.vue';

export default {
  name: 'SubscriptionsPage',
  components: {
    GlEmptyState,
    SubscriptionsList,
    AddNamespaceButton,
  },
  props: {
    hasSubscriptions: {
      type: Boolean,
      required: true,
    },
  },
};
</script>

<template>
  <div v-if="hasSubscriptions">
    <div class="gl-display-flex gl-justify-content-end">
      <add-namespace-button />
    </div>

    <subscriptions-list />
  </div>
  <gl-empty-state
    v-else
    :title="s__('Integrations|No linked namespaces')"
    :description="
      s__(
        'Integrations|Namespaces are the GitLab groups and subgroups you link to this Jira instance.',
      )
    "
  >
    <template #actions>
      <add-namespace-button />
    </template>
  </gl-empty-state>
</template>
