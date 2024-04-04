import { GlBadge } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import HeaderBadges from '~/ci/pipeline_details/header/components/header_badges.vue';

import { pipelineHeaderSuccess, pipelineHeaderTrigger } from '../../mock_data';

describe('Header badges', () => {
  let wrapper;

  const findAllBadges = () => wrapper.findAllComponents(GlBadge);

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
    expect(wrapper.findByText('trigger token').exists()).toBe(false);
  });

  it('displays tooltips for badges', () => {
    createComponent();

    expect(wrapper.findByText('merged results').attributes('title')).toBe(
      'This pipeline ran on the contents of the merge request combined with the contents of the target branch.',
    );
    expect(wrapper.findByText('Scheduled').attributes('title')).toBe(
      'This pipeline was created by a schedule',
    );
  });

  it('displays triggered badge', () => {
    createComponent(pipelineHeaderTrigger.data.project.pipeline);

    expect(findAllBadges()).toHaveLength(3);
    expect(wrapper.findByText('merged results').exists()).toBe(true);
    expect(wrapper.findByText('Scheduled').exists()).toBe(true);
    expect(wrapper.findByText('trigger token').exists()).toBe(true);
  });
});
