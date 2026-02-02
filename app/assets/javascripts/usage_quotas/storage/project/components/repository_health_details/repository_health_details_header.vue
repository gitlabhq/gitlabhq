<script>
import { GlButton, GlSprintf } from '@gitlab/ui';
import { formatDate } from '~/lib/utils/datetime_utility';
import { __ } from '~/locale';

export default {
  name: 'RepositoryHealthDetailsHeader',
  components: {
    GlButton,
    GlSprintf,
  },
  props: {
    healthDetails: {
      type: Object,
      required: true,
    },
  },
  emits: ['regenerate-report'],
  computed: {
    lastUpdatedAt() {
      return this.healthDetails.updatedAt
        ? formatDate(this.healthDetails.updatedAt)
        : __('Unknown');
    },
  },
};
</script>

<template>
  <div class="gl-flex">
    <h4 class="gl-my-0" data-testid="repository-health-header-title">
      {{ s__('UsageQuota|Repository health') }}
    </h4>
    <div class="gl-ml-auto gl-text-right">
      <gl-button class="gl-mb-2 gl-ml-auto" @click="$emit('regenerate-report')">{{
        s__('UsageQuota|Regenerate report')
      }}</gl-button>
      <p
        class="gl-text-sm gl-font-300 gl-italic"
        data-testid="repository-health-header-last-updated"
      >
        <gl-sprintf :message="s__('UsageQuota|Last update: %{date}')">
          <template #date>
            {{ lastUpdatedAt }}
          </template>
        </gl-sprintf>
      </p>
    </div>
  </div>
</template>
