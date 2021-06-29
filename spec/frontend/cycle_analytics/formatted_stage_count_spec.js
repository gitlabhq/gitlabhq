import { shallowMount } from '@vue/test-utils';
import Component from '~/cycle_analytics/components/formatted_stage_count.vue';

describe('Formatted Stage Count', () => {
  let wrapper = null;

  const createComponent = (stageCount = null) => {
    wrapper = shallowMount(Component, {
      propsData: {
        stageCount,
      },
    });
  };

  beforeEach(() => {
    createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it.each`
    stageCount | expectedOutput
    ${null}    | ${'-'}
    ${1}       | ${'1 item'}
    ${10}      | ${'10 items'}
    ${1000}    | ${'1,000 items'}
    ${1001}    | ${'1,000+ items'}
  `('returns "$expectedOutput" for stageCount=$stageCount', ({ stageCount, expectedOutput }) => {
    createComponent(stageCount);
    expect(wrapper.text()).toContain(expectedOutput);
  });
});
