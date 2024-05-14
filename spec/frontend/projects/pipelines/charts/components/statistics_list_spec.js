import { GlLink } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Component from '~/projects/pipelines/charts/components/statistics_list.vue';
import { counts } from '../mock_data';

describe('StatisticsList', () => {
  let wrapper;

  const failedPipelinesLink = '/flightjs/Flight/-/pipelines?page=1&scope=all&status=failed';

  const findFailedPipelinesLink = () => wrapper.findComponent(GlLink);

  beforeEach(() => {
    wrapper = shallowMount(Component, {
      provide: {
        failedPipelinesLink,
      },
      propsData: {
        counts,
      },
    });
  });

  it('displays the counts data with labels', () => {
    expect(wrapper.element).toMatchSnapshot();
  });

  it('displays failed pipelines link', () => {
    expect(findFailedPipelinesLink().attributes('href')).toBe(failedPipelinesLink);
  });

  describe('with no failed piplines link', () => {
    beforeEach(() => {
      wrapper = shallowMount(Component, {
        propsData: {
          counts,
        },
      });
    });

    it('hides the failed pipelines link', () => {
      expect(findFailedPipelinesLink().exists()).toBe(false);
    });
  });
});
