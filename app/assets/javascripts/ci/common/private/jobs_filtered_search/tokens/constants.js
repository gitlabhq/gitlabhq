import { s__ } from '~/locale';

export const JOB_SOURCES = [
  {
    text: s__('JobSource|Push'),
    value: 'PUSH',
  },
  {
    text: s__('JobSource|Web'),
    value: 'WEB',
  },
  {
    text: s__('JobSource|Trigger'),
    value: 'TRIGGER',
  },
  {
    text: s__('JobSource|Schedule'),
    value: 'SCHEDULE',
  },
  {
    text: s__('JobSource|API'),
    value: 'API',
  },
  {
    text: s__('JobSource|External'),
    value: 'EXTERNAL',
  },
  {
    text: s__('JobSource|Pipeline'),
    value: 'PIPELINE',
  },
  {
    text: s__('JobSource|Chat'),
    value: 'CHAT',
  },
  {
    text: s__('JobSource|Web IDE'),
    value: 'WEBIDE',
  },
  {
    text: s__('JobSource|Merge Request'),
    value: 'MERGE_REQUEST_EVENT',
  },
  {
    text: s__('JobSource|External Pull Request'),
    value: 'EXTERNAL_PULL_REQUEST_EVENT',
  },
  {
    text: s__('JobSource|Parent Pipeline'),
    value: 'PARENT_PIPELINE',
  },
  {
    text: s__('JobSource|Container Registry Push'),
    value: 'CONTAINER_REGISTRY_PUSH',
  },
  {
    text: s__('JobSource|Unknown'),
    value: 'UNKNOWN',
  },
];
