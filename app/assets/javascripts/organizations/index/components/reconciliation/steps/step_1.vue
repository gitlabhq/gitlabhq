<script>
import illustrationUrl from '@gitlab/svgs/dist/illustrations/empty-state/empty-organizations-add-md.svg?url';
import HelpPageLink from '~/vue_shared/components/help_page_link/help_page_link.vue';
import OrganizationCard from '../organization_card.vue';
import BaseStep from './base_step.vue';

export default {
  name: 'ReconciliationStep1',
  illustrationUrl,
  components: {
    BaseStep,
    OrganizationCard,
    HelpPageLink,
  },
  props: {
    organizations: {
      type: Array,
      required: true,
    },
  },
};
</script>

<template>
  <base-step
    :title="s__('Organization|Activate your Organizations')"
    :illustration="$options.illustrationUrl"
  >
    <template #description>
      <p>
        {{
          s__(
            "Organization|We'll create one Organization per top-level group. You can reassign groups between them in the next step.",
          )
        }}
      </p>

      <p>
        <help-page-link href="user/organization/_index.md">{{
          s__('Organization|Learn how Organizations work')
        }}</help-page-link>
      </p>
    </template>
    <div class="gl-p-2">
      <div class="-gl-m-2 gl-flex gl-flex-wrap gl-pb-4">
        <div
          v-for="organization in organizations"
          :key="organization.id"
          class="gl-w-1/2 gl-p-2 first:gl-ml-auto last:gl-mr-auto @lg:gl-w-1/3"
        >
          <organization-card :organization="organization" />
        </div>
      </div>
    </div>
  </base-step>
</template>
