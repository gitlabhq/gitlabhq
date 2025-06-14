<script>
import { GlIcon, GlLink } from '@gitlab/ui';

export default {
  name: 'MergeRequestsWidget',
  components: {
    GlIcon,
    GlLink,
  },
  props: {
    reviewRequestedPath: {
      type: String,
      required: true,
    },
    assignedToYouPath: {
      type: String,
      required: true,
    },
  },
};
</script>

<template>
  <div class="gl-border gl-rounded-lg gl-px-4 gl-py-1">
    <h4 class="gl-flex gl-items-center gl-gap-2">
      <gl-icon name="merge-request" :size="16" />{{ __('Merge requests') }}
    </h4>
    <ul class="gl-list-none gl-p-0">
      <li>
        <gl-link :href="reviewRequestedPath">{{ __('Review requested') }}</gl-link>
      </li>
      <li>
        <gl-link :href="assignedToYouPath">{{ __('Assigned to you') }}</gl-link>
      </li>
    </ul>
  </div>
</template>
