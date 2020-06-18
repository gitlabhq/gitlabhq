import { GlSkeletonLoading } from '@gitlab/ui';
import { plans } from './mock_data';
import { shallowMount } from '@vue/test-utils';
import axios from '~/lib/utils/axios_utils';
import MockAdapter from 'axios-mock-adapter';
import MrWidgetTerraformContainer from '~/vue_merge_request_widget/components/terraform/mr_widget_terraform_container.vue';
import Poll from '~/lib/utils/poll';
import TerraformPlan from '~/vue_merge_request_widget/components/terraform/terraform_plan.vue';

describe('MrWidgetTerraformConainer', () => {
  let mock;
  let wrapper;

  const propsData = { endpoint: '/path/to/terraform/report.json' };

  const findPlans = () => wrapper.findAll(TerraformPlan).wrappers.map(x => x.props('plan'));

  const mockPollingApi = (response, body, header) => {
    mock.onGet(propsData.endpoint).reply(response, body, header);
  };

  const mountWrapper = () => {
    wrapper = shallowMount(MrWidgetTerraformContainer, { propsData });
    return axios.waitForAll();
  };

  beforeEach(() => {
    mock = new MockAdapter(axios);
  });

  afterEach(() => {
    wrapper.destroy();
    mock.restore();
  });

  describe('when data is loading', () => {
    beforeEach(() => {
      mockPollingApi(200, plans, {});

      return mountWrapper().then(() => {
        wrapper.setData({ loading: true });
        return wrapper.vm.$nextTick();
      });
    });

    it('diplays loading skeleton', () => {
      expect(wrapper.find(GlSkeletonLoading).exists()).toBe(true);

      expect(findPlans()).toEqual([]);
    });
  });

  describe('polling', () => {
    let pollRequest;
    let pollStop;

    beforeEach(() => {
      pollRequest = jest.spyOn(Poll.prototype, 'makeRequest');
      pollStop = jest.spyOn(Poll.prototype, 'stop');
    });

    afterEach(() => {
      pollRequest.mockRestore();
      pollStop.mockRestore();
    });

    describe('successful poll', () => {
      beforeEach(() => {
        mockPollingApi(200, plans, {});

        return mountWrapper();
      });

      it('diplays terraform components and stops loading', () => {
        expect(wrapper.find(GlSkeletonLoading).exists()).toBe(false);

        expect(findPlans()).toEqual(Object.values(plans));
      });

      it('does not make additional requests after poll is successful', () => {
        expect(pollRequest).toHaveBeenCalledTimes(1);
        expect(pollStop).toHaveBeenCalledTimes(1);
      });
    });

    describe('polling fails', () => {
      beforeEach(() => {
        mockPollingApi(500, null, {});
        return mountWrapper();
      });

      it('stops loading', () => {
        expect(wrapper.find(GlSkeletonLoading).exists()).toBe(false);
      });

      it('generates one broken plan', () => {
        expect(findPlans()).toEqual([{}]);
      });

      it('does not make additional requests after poll is unsuccessful', () => {
        expect(pollRequest).toHaveBeenCalledTimes(1);
        expect(pollStop).toHaveBeenCalledTimes(1);
      });
    });
  });
});
