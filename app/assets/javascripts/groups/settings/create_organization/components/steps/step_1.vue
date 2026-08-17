<script>
import illustrationUrl from '@gitlab/svgs/dist/illustrations/empty-state/empty-organizations-add-md.svg?url';
import HelpPageLink from '~/vue_shared/components/help_page_link/help_page_link.vue';
import OrganizationCard from '../organization_card.vue';
import OrganizationGroupStats from '../organization_group_stats.vue';
import BaseStep from './base_step.vue';

export default {
  name: 'ReconciliationStep1',
  illustrationUrl,
  components: {
    BaseStep,
    OrganizationCard,
    OrganizationGroupStats,
    HelpPageLink,
  },
  inheritAttrs: false,
  props: {
    organization: {
      type: Object,
      required: true,
    },
  },
};
</script>

<template>
  <base-step
    :title="s__('Organization|Create your Organizations')"
    :illustration="$options.illustrationUrl"
  >
    <template #description>
      <p>
        {{
          s__(
            'Organization|Create an organization to manage your top-level groups. You can set up your organization structure in the next step.',
          )
        }}
      </p>

      <p>
        <help-page-link href="user/organization/_index.md">{{
          s__('Organization|Learn how Organizations work')
        }}</help-page-link>
      </p>
    </template>
    <div class="gl-flex gl-w-full gl-justify-center">
      <div class="gl-w-1/2 @lg:gl-w-1/3">
        <organization-card :organization="organization">
          <div
            v-for="group in organization.groups.nodes"
            :key="group.id"
            class="gl-rounded-xl gl-bg-default gl-p-4"
          >
            <organization-group-stats :group="group" />
          </div>
        </organization-card>
      </div>
    </div>
  </base-step>
</template>
