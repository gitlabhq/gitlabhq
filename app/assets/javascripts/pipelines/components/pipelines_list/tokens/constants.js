import { s__ } from '~/locale';

export const PIPELINE_SOURCES = [
  {
    text: s__('Pipeline|Source|Push'),
    value: 'push',
  },
  {
    text: s__('Pipeline|Source|Web'),
    value: 'web',
  },
  {
    text: s__('Pipeline|Source|Trigger'),
    value: 'trigger',
  },
  {
    text: s__('Pipeline|Source|Schedule'),
    value: 'schedule',
  },
  {
    text: s__('Pipeline|Source|API'),
    value: 'api',
  },
  {
    text: s__('Pipeline|Source|External'),
    value: 'external',
  },
  {
    text: s__('Pipeline|Source|Pipeline'),
    value: 'pipeline',
  },
  {
    text: s__('Pipeline|Source|Chat'),
    value: 'chat',
  },
  {
    text: s__('Pipeline|Source|Web IDE'),
    value: 'webide',
  },
  {
    text: s__('Pipeline|Source|Merge Request'),
    value: 'merge_request_event',
  },
  {
    text: s__('Pipeline|Source|External Pull Request'),
    value: 'external_pull_request_event',
  },
  {
    text: s__('Pipeline|Source|Parent Pipeline'),
    value: 'parent_pipeline',
  },
];
