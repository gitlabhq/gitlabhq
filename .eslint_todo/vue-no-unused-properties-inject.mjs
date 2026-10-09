/**
 * Files with unused `inject` entries. The `inject` group of
 * `vue/no-unused-properties` is dropped here; the other groups still apply.
 * Started as the generated list for the former `local-rules/vue-no-unused-injects`.
 */
export default {
  files: [
    'app/assets/javascripts/issues/dashboard/components/issues_dashboard_app.vue',
    'app/assets/javascripts/repository/components/header_area.vue',
    'app/assets/javascripts/repository/components/header_area/breadcrumbs.vue',
    'ee/app/assets/javascripts/security_orchestration/components/policies/app.vue',
    'ee/app/assets/javascripts/usage_quotas/code_suggestions/components/add_on_eligible_user_list.vue',
  ],
  rules: {
    'vue/no-unused-properties': [
      'error',
      {
        groups: ['props', 'data', 'computed', 'methods', 'setup'],
      },
    ],
  },
};
