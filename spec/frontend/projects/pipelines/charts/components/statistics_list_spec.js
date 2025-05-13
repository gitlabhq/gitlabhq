import { nextTick } from 'vue';
import { GlLink, GlSkeletonLoader } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Component from '~/projects/pipelines/charts/components/statistics_list.vue';

import { InternalEvents } from '~/tracking';
import { mockTracking } from 'helpers/tracking_helper';
import { counts } from 'jest/analytics/ci_cd/mock_data';

describe('StatisticsList', () => {
  let wrapper;
  let trackingSpy;

  const failedPipelinesLink = '/flightjs/Flight/-/pipelines?page=1&scope=all&status=failed';

  const findFailedPipelinesLink = () => wrapper.findComponent(GlLink);
  const findSkeletonLoader = () => wrapper.findComponent(GlSkeletonLoader);

  const createComponent = ({ props } = {}) => {
    wrapper = shallowMount(Component, {
      provide: {
        failedPipelinesLink,
      },
      propsData: {
        counts,
        ...props,
      },
    });
  };

  beforeEach(() => {
    trackingSpy = mockTracking(undefined, window.document, jest.spyOn);

    createComponent();
  });

  it('displays loading state', () => {
    createComponent({ props: { loading: true } });

    expect(findSkeletonLoader().exists()).toBe(true);
  });

  it('displays the counts data with labels', () => {
    expect(wrapper.element).toMatchSnapshot();
  });

  it('displays failed pipelines link', () => {
    expect(findFailedPipelinesLink().attributes('href')).toBe(failedPipelinesLink);
  });

  describe('when View All link is clicked', () => {
    beforeEach(async () => {
      InternalEvents.bindInternalEventDocument(findFailedPipelinesLink().element);
      await findFailedPipelinesLink().trigger('click');
      await nextTick();
    });

    it('should track that the View All link has been clicked', () => {
      expect(trackingSpy).toHaveBeenCalledWith(
        undefined,
        'click_view_all_link_in_pipeline_analytics',
        expect.any(Object),
      );
    });
  });

  describe('with no failed pipelines link', () => {
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
