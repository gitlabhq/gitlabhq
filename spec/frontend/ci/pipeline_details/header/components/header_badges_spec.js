import { GlBadge, GlSprintf } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import HeaderBadges from '~/ci/pipeline_details/header/components/header_badges.vue';

import { PIPELINE_TYPE_BRANCH, PIPELINE_TYPE_TAG } from '~/ci/pipeline_details/header/constants';
import { pipelineHeaderSuccess, pipelineHeaderTrigger } from '../../mock_data';

describe('Header badges', () => {
  let wrapper;

  const findAllBadges = () => wrapper.findAllComponents(GlBadge).wrappers;
  const findChildPipelineBadge = () =>
    findAllBadges().filter((badge) => {
      const sprintf = badge.findComponent(GlSprintf);
      return sprintf.exists() && sprintf.attributes('message').includes('Child pipeline');
    });

  const createComponent = (mockPipeline = pipelineHeaderSuccess.data.project.pipeline) => {
    wrapper = shallowMountExtended(HeaderBadges, {
      propsData: {
        pipeline: mockPipeline,
      },
    });
  };

  it('displays default badges', () => {
    createComponent();

    expect(findAllBadges()).toHaveLength(2);
    expect(wrapper.findByText('merged results').exists()).toBe(true);
    expect(wrapper.findByText('Scheduled').exists()).toBe(true);
    expect(wrapper.findByText('branch').exists()).toBe(false);
    expect(wrapper.findByText('tag').exists()).toBe(false);
  });

  it('displays tooltips for badges', () => {
    createComponent();

    expect(wrapper.findByTestId('badges-merged-results').attributes('title')).toBe(
      'This pipeline ran on the contents of the merge request combined with the contents of the target branch.',
    );
    expect(wrapper.findByTestId('badges-scheduled').attributes('title')).toBe(
      'This pipeline was created by a schedule',
    );
  });

  it('displays triggered badge', () => {
    createComponent(pipelineHeaderTrigger.data.project.pipeline);

    expect(findAllBadges()).toHaveLength(3);
    expect(wrapper.findByText('merged results').exists()).toBe(true);
    expect(wrapper.findByText('Scheduled').exists()).toBe(true);
    expect(wrapper.findByText('trigger token').exists()).toBe(true);
    expect(wrapper.findByText('branch').exists()).toBe(false);
    expect(wrapper.findByText('tag').exists()).toBe(false);
  });

  describe('in a child pipeline', () => {
    const triggeredByPath = 'https://example.com';

    it('displays the link to the parent', () => {
      createComponent({
        ...pipelineHeaderTrigger.data.project.pipeline,
        child: true,
        triggeredByPath,
      });

      expect(findAllBadges()).toHaveLength(4);
      expect(findChildPipelineBadge()).toHaveLength(1);
    });
  });

  describe('in a tag pipeline', () => {
    it('displays only tag pipeline type badge', () => {
      createComponent({
        ...pipelineHeaderSuccess.data.project.pipeline,
        type: PIPELINE_TYPE_TAG,
        mergeRequestEventType: '',
      });

      expect(wrapper.findByText('merged results').exists()).toBe(false);
      expect(wrapper.findByText('branch').exists()).toBe(false);
      expect(wrapper.findByTestId('badges-tag').attributes('title')).toBe(
        'This pipeline ran for a tag.',
      );
    });
  });

  describe('in a branch pipeline', () => {
    it('displays only branch pipeline type badge', () => {
      createComponent({
        ...pipelineHeaderSuccess.data.project.pipeline,
        type: PIPELINE_TYPE_BRANCH,
        mergeRequestEventType: '',
      });

      expect(wrapper.findByText('merged results').exists()).toBe(false);
      expect(wrapper.findByText('tag').exists()).toBe(false);
      expect(wrapper.findByTestId('badges-branch').attributes('title')).toBe(
        'This pipeline ran for a branch.',
      );
    });
  });
});
