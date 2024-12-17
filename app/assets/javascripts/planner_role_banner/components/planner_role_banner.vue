<script>
import { GlBanner, GlLink, GlSprintf } from '@gitlab/ui';
import ADD_USER_SVG_URL from '@gitlab/svgs/dist/illustrations/add-user-sm.svg';
import { helpPagePath } from '~/helpers/help_page_helper';
import { s__ } from '~/locale';
import UserCalloutDismisser from '~/vue_shared/components/user_callout_dismisser.vue';

export default {
  name: 'PlannerRoleBanner',
  i18n: {
    title: s__('MemberRole|New Planner role'),
    buttonText: s__('MemberRole|Learn more about roles and permissions'), // This is hidden but it is required prop
    description:
      s__(`MemberRole|The Planner role is a hybrid of the existing Guest and Reporter roles but designed for users who need access to planning workflows. For more information about the new role, see %{blogLinkStart}our blog%{blogLinkEnd} or %{learnMoreStart}learn more about roles and permissions%{learnMoreEnd}.
`),
    dismissLabel: s__('MemberRole|Dismiss Planner role promotion'),
  },
  blogURL:
    'https://about.gitlab.com/blog/2024/11/25/introducing-gitlabs-new-planner-role-for-agile-planning-teams/',
  docsUrl: helpPagePath('user/permissions'),
  ADD_USER_SVG_URL,
  buttonAttributes: {
    class: 'planner-role-banner-button',
  },
  components: {
    GlBanner,
    UserCalloutDismisser,
    GlLink,
    GlSprintf,
  },
};
</script>
<template>
  <user-callout-dismisser feature-name="planner_role_callout">
    <template #default="{ dismiss, shouldShowCallout }">
      <div v-if="shouldShowCallout" class="gl-pt-5">
        <gl-banner
          :title="$options.i18n.title"
          :button-text="$options.i18n.buttonText"
          :button-link="$options.docsUrl"
          :svg-path="$options.ADD_USER_SVG_URL"
          :button-attributes="$options.buttonAttributes"
          :dismiss-label="$options.i18n.dismissLabel"
          data-testid="planner-role-banner"
          variant="promotion"
          @close="dismiss"
        >
          <span>
            <gl-sprintf :message="$options.i18n.description">
              <template #blogLink="{ content }">
                <gl-link :href="$options.blogURL" target="_blank">{{ content }}</gl-link>
              </template>
              <template #learnMore="{ content }">
                <gl-link :href="$options.docsUrl">{{ content }}</gl-link>
              </template>
            </gl-sprintf>
          </span>
        </gl-banner>
      </div>
    </template>
  </user-callout-dismisser>
</template>
<!-- As per the requirement, the link button is not required and banner is not support hiding the link button -->
<style>
.planner-role-banner-button {
  display: none;
}
</style>
