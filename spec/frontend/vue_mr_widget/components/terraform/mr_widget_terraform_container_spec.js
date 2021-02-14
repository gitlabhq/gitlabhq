import { GlDeprecatedSkeletonLoading as GlSkeletonLoading, GlSprintf } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import MockAdapter from 'axios-mock-adapter';
import axios from '~/lib/utils/axios_utils';
import Poll from '~/lib/utils/poll';
import MrWidgetExpanableSection from '~/vue_merge_request_widget/components/mr_widget_expandable_section.vue';
import MrWidgetTerraformContainer from '~/vue_merge_request_widget/components/terraform/mr_widget_terraform_container.vue';
import TerraformPlan from '~/vue_merge_request_widget/components/terraform/terraform_plan.vue';
import { invalidPlanWithName, plans, validPlanWithName } from './mock_data';

describe('MrWidgetTerraformConainer', () => {
  let mock;
  let wrapper;

  const propsData = { endpoint: '/path/to/terraform/report.json' };

  const findHeader = () => wrapper.find('[data-testid="terraform-header-text"]');
  const findPlans = () => wrapper.findAll(TerraformPlan).wrappers.map((x) => x.props('plan'));

  const mockPollingApi = (response, body, header) => {
    mock.onGet(propsData.endpoint).reply(response, body, header);
  };

  const mountWrapper = () => {
    wrapper = shallowMount(MrWidgetTerraformContainer, {
      propsData,
      stubs: { MrWidgetExpanableSection, GlSprintf },
    });
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
      expect(wrapper.find(MrWidgetExpanableSection).exists()).toBe(false);
    });
  });

  describe('when data has finished loading', () => {
    beforeEach(() => {
      mockPollingApi(200, plans, {});
      return mountWrapper();
    });

    it('displays terraform content', () => {
      expect(wrapper.find(GlSkeletonLoading).exists()).toBe(false);
      expect(wrapper.find(MrWidgetExpanableSection).exists()).toBe(true);
      expect(findPlans()).toEqual(Object.values(plans));
    });

    describe('when data includes one invalid plan', () => {
      beforeEach(() => {
        const invalidPlanGroup = { bad_plan: invalidPlanWithName };
        mockPollingApi(200, invalidPlanGroup, {});
        return mountWrapper();
      });

      it('displays header text for one invalid plan', () => {
        expect(findHeader().text()).toBe('1 Terraform report failed to generate');
      });
    });

    describe('when data includes multiple invalid plans', () => {
      beforeEach(() => {
        const invalidPlanGroup = {
          bad_plan_one: invalidPlanWithName,
          bad_plan_two: invalidPlanWithName,
        };

        mockPollingApi(200, invalidPlanGroup, {});
        return mountWrapper();
      });

      it('displays header text for multiple invalid plans', () => {
        expect(findHeader().text()).toBe('2 Terraform reports failed to generate');
      });
    });

    describe('when data includes one valid plan', () => {
      beforeEach(() => {
        const validPlanGroup = { valid_plan: validPlanWithName };
        mockPollingApi(200, validPlanGroup, {});
        return mountWrapper();
      });

      it('displays header text for one valid plans', () => {
        expect(findHeader().text()).toBe('1 Terraform report was generated in your pipelines');
      });
    });

    describe('when data includes multiple valid plans', () => {
      beforeEach(() => {
        const validPlanGroup = {
          valid_plan_one: validPlanWithName,
          valid_plan_two: validPlanWithName,
        };
        mockPollingApi(200, validPlanGroup, {});
        return mountWrapper();
      });

      it('displays header text for multiple valid plans', () => {
        expect(findHeader().text()).toBe('2 Terraform reports were generated in your pipelines');
      });
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
        expect(findPlans()).toEqual([{ tf_report_error: 'api_error' }]);
      });

      it('does not make additional requests after poll is unsuccessful', () => {
        expect(pollRequest).toHaveBeenCalledTimes(1);
        expect(pollStop).toHaveBeenCalledTimes(1);
      });
    });
  });
});
