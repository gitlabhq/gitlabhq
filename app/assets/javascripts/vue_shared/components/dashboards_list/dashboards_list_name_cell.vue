<script>
import { GlButton, GlLink, GlTruncate } from '@gitlab/ui';
import { __, sprintf } from '~/locale';

export default {
  name: 'DashboardsListNameCell',
  components: {
    GlButton,
    GlLink,
    GlTruncate,
  },
  props: {
    name: {
      type: String,
      required: true,
    },
    description: {
      type: String,
      required: true,
    },
    dashboardUrl: {
      type: String,
      required: true,
    },
    isStarred: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    starIcon() {
      return this.isStarred ? 'star' : 'star-o';
    },
    starTitle() {
      return this.isStarred ? __('Remove from favorites') : __('Add to favorites');
    },
    starAriaLabel() {
      const str = this.isStarred
        ? __('Remove %{name} from favorites')
        : __('Add %{name} to favorites');
      return sprintf(str, { name: this.name });
    },
  },
};
</script>
<template>
  <div class="gl-inline-block gl-w-full gl-min-w-1 gl-flex-row gl-items-center sm:gl-flex">
    <gl-button
      class="sm:gl-mr-3"
      category="tertiary"
      variant="default"
      data-testid="dashboard-star-icon"
      :aria-label="starAriaLabel"
      :title="starTitle"
      :icon="starIcon"
    />

    <div class="gl-flex-1 gl-flex-col gl-text-right sm:gl-w-48 sm:gl-text-left">
      <gl-link
        data-testid="dashboard-redirect-link"
        :href="dashboardUrl"
        class="gl-font-bold gl-text-black !gl-no-underline"
        >{{ name }}</gl-link
      >
      <div>
        <gl-truncate :text="description" with-tooltip />
      </div>
    </div>
  </div>
</template>
