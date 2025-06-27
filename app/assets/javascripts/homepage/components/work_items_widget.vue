<script>
import { GlIcon, GlLink } from '@gitlab/ui';

export default {
  name: 'WorkItemsWidget',
  components: {
    GlIcon,
    GlLink,
  },
  props: {
    assignedToYouPath: {
      type: String,
      required: true,
    },
    authoredByYouPath: {
      type: String,
      required: true,
    },
  },
};
</script>

<template>
  <div class="gl-border gl-rounded-lg gl-px-4 gl-py-1">
    <h4 class="gl-flex gl-items-center gl-gap-2">
      <gl-icon name="work-items" :size="16" />{{ __('Work items') }}
    </h4>
    <ul class="gl-list-none gl-p-0">
      <li>
        <gl-link
          class="gl-flex gl-items-center gl-gap-3 gl-rounded-small gl-px-1 gl-py-1 !gl-no-underline hover:gl-bg-gray-10 dark:hover:gl-bg-alpha-light-8"
          variant="meta"
          :href="assignedToYouPath"
        >
          {{ s__('HomePageWorkItemsWidget|Assigned to you') }}
        </gl-link>
      </li>
      <li>
        <gl-link
          class="gl-flex gl-items-center gl-gap-3 gl-rounded-small gl-px-1 gl-py-1 !gl-no-underline hover:gl-bg-gray-10 dark:hover:gl-bg-alpha-light-8"
          variant="meta"
          :href="authoredByYouPath"
        >
          {{ s__('HomePageWorkItemsWidget|Authored by you') }}
        </gl-link>
      </li>
    </ul>
  </div>
</template>
