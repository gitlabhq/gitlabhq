import { __ } from '~/locale';

export const WORK_ITEMS_SURVEY_COOKIE_NAME = 'hide_work_items_hierarchy_survey';

/**
 * Hard-coded strings since we're rendering hierarchy
 * items from mock responses. Remove this when we
 * have a real hierarchy endpoint.
 */
export const LICENSE_PLAN = {
  FREE: 'free',
  PREMIUM: 'premium',
  ULTIMATE: 'ultimate',
};

export const workItemTypes = {
  EPIC: {
    title: __('Epic'),
    icon: 'epic',
    color: '#694CC0',
    backgroundColor: '#E1D8F9',
  },
  ISSUE: {
    title: __('Issue'),
    icon: 'issues',
    color: '#1068BF',
    backgroundColor: '#CBE2F9',
  },
  TASK: {
    title: __('Task'),
    icon: 'todo-done',
    color: '#217645',
    backgroundColor: '#C3E6CD',
    isWorkItem: true,
  },
  INCIDENT: {
    title: __('Incident'),
    icon: 'issue-type-incident',
    backgroundColor: '#db2a0f',
    color: '#FDD4CD',
    iconSize: 16,
  },
  SUB_EPIC: {
    title: __('Child epic'),
    icon: 'epic',
    color: '#AB6100',
    backgroundColor: '#F5D9A8',
  },
  REQUIREMENT: {
    title: __('Requirement'),
    icon: 'requirements',
    color: '#0068c5',
    backgroundColor: '#c5e3fb',
  },
  TEST_CASE: {
    title: __('Test case'),
    icon: 'issue-type-test-case',
    backgroundColor: '#007a3f',
    color: '#bae8cb',
    iconSize: 16,
  },
};
