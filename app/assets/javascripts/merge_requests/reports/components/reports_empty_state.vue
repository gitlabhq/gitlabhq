<script>
import { GlEmptyState } from '@gitlab/ui';
import NO_PIPELINE_SVG from '@gitlab/svgs/dist/illustrations/empty-state/empty-pipeline-md.svg?url';
import PIPELINE_RUNNING_SVG from '@gitlab/svgs/dist/illustrations/empty-state/empty-job-pending-md.svg?url';
import NO_REPORTS_SVG from '@gitlab/svgs/dist/illustrations/empty-state/empty-artifacts-md.svg?url';
import { helpPagePath } from '~/helpers/help_page_helper';
import { s__ } from '~/locale';
import {
  EMPTY_STATE_NO_PIPELINE,
  EMPTY_STATE_PIPELINE_RUNNING,
  EMPTY_STATE_NO_REPORTS,
} from '../constants';

const EMPTY_STATES = {
  [EMPTY_STATE_NO_PIPELINE]: {
    svgPath: NO_PIPELINE_SVG,
    title: s__('MrReports|No pipeline results yet'),
    description: s__('MrReports|Start a pipeline to generate reports.'),
    buttonText: s__('MrReports|View CI/CD documentation'),
    buttonLink: helpPagePath('ci/_index'),
  },
  [EMPTY_STATE_PIPELINE_RUNNING]: {
    svgPath: PIPELINE_RUNNING_SVG,
    title: s__('MrReports|Pipeline is running'),
    description: s__(
      'MrReports|Reports appear here when the pipeline finishes. This page updates automatically.',
    ),
    buttonText: s__('MrReports|View running pipeline'),
    buttonLink: null,
  },
  [EMPTY_STATE_NO_REPORTS]: {
    svgPath: NO_REPORTS_SVG,
    title: s__('MrReports|No scanning jobs configured'),
    description: s__('MrReports|Add a scanning job to your CI/CD pipeline to see reports here.'),
    buttonText: s__('MrReports|View reports documentation'),
    buttonLink: helpPagePath('user/project/merge_requests/reports'),
  },
};

export default {
  name: 'ReportsEmptyState',
  components: {
    GlEmptyState,
  },
  props: {
    type: {
      type: String,
      required: true,
      validator: (value) => Object.keys(EMPTY_STATES).includes(value),
    },
    pipelinePath: {
      type: String,
      required: false,
      default: '',
    },
  },
  computed: {
    emptyState() {
      return EMPTY_STATES[this.type];
    },
    buttonLink() {
      return this.emptyState.buttonLink ?? this.pipelinePath;
    },
  },
};
</script>

<template>
  <gl-empty-state
    :title="emptyState.title"
    :description="emptyState.description"
    :svg-path="emptyState.svgPath"
    :svg-height="145"
    :header-level="3"
    :primary-button-link="buttonLink"
    :primary-button-text="emptyState.buttonText"
  />
</template>
