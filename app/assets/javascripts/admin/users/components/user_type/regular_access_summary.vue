<script>
import { GlSprintf } from '@gitlab/ui';
import HelpPageLink from '~/vue_shared/components/help_page_link/help_page_link.vue';
import AccessSummary from './access_summary.vue';

export default {
  components: { AccessSummary, GlSprintf, HelpPageLink },
};
</script>

<template>
  <access-summary>
    <template #admin-content>
      <slot></slot>
    </template>
    <template v-if="!$scopedSlots.default" #admin-list>
      <li>{{ s__('AdminUsers|No access.') }}</li>
    </template>

    <template #group-list>
      <li>
        <gl-sprintf
          :message="
            s__(
              'AdminUsers|Based on member role in groups and projects. %{linkStart}Learn more about member roles.%{linkEnd}',
            )
          "
        >
          <template #link="{ content }">
            <help-page-link href="user/permissions" target="_blank">{{ content }}</help-page-link>
          </template>
        </gl-sprintf>
      </li>
    </template>

    <template #settings-list>
      <li>
        {{ s__('AdminUsers|Requires at least Maintainer role in specific groups and projects.') }}
      </li>
    </template>
  </access-summary>
</template>
