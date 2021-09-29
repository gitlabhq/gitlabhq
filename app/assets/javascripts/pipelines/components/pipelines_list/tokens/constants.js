import { s__ } from '~/locale';

export const PIPELINE_SOURCES = [
  {
    text: s__('PipelineSource|Push'),
    value: 'push',
  },
  {
    text: s__('PipelineSource|Web'),
    value: 'web',
  },
  {
    text: s__('PipelineSource|Trigger'),
    value: 'trigger',
  },
  {
    text: s__('PipelineSource|Schedule'),
    value: 'schedule',
  },
  {
    text: s__('PipelineSource|API'),
    value: 'api',
  },
  {
    text: s__('PipelineSource|External'),
    value: 'external',
  },
  {
    text: s__('PipelineSource|Pipeline'),
    value: 'pipeline',
  },
  {
    text: s__('PipelineSource|Chat'),
    value: 'chat',
  },
  {
    text: s__('PipelineSource|Web IDE'),
    value: 'webide',
  },
  {
    text: s__('PipelineSource|Merge Request'),
    value: 'merge_request_event',
  },
  {
    text: s__('PipelineSource|External Pull Request'),
    value: 'external_pull_request_event',
  },
  {
    text: s__('PipelineSource|Parent Pipeline'),
    value: 'parent_pipeline',
  },
];
