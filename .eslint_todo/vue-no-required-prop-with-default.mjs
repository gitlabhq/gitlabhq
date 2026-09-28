export default {
  files: [
    'app/assets/javascripts/boards/components/item_count.vue',
    'app/assets/javascripts/boards/components/weight_count.vue',
    'app/assets/javascripts/environments/folder/environments_folder_app.vue',
    'app/assets/javascripts/sidebar/components/reviewers/uncollapsed_reviewer_list.vue',
    'ee/app/assets/javascripts/compliance_dashboard/components/shared/framework_badge.vue',
    'ee/app/assets/javascripts/security_dashboard/components/shared/vulnerability_report/vulnerability_path.vue',
    'ee/app/assets/javascripts/security_orchestration/components/policy_editor/scope/scope_section.vue',
    'ee/app/assets/javascripts/work_items/components/shared/work_item_status_badge.vue',
  ],
  rules: {
    'vue/no-required-prop-with-default': 'off',
  },
};
