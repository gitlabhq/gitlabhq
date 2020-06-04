import { GlLink, GlLoadingIcon, GlSprintf } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import axios from '~/lib/utils/axios_utils';
import MockAdapter from 'axios-mock-adapter';
import MrWidgetTerraformPlan from '~/vue_merge_request_widget/components/mr_widget_terraform_plan.vue';
import Poll from '~/lib/utils/poll';

const plan = {
  create: 10,
  update: 20,
  delete: 30,
  job_path: '/path/to/ci/logs',
};

describe('MrWidgetTerraformPlan', () => {
  let mock;
  let wrapper;

  const propsData = { endpoint: '/path/to/terraform/report.json' };

  const mockPollingApi = (response, body, header) => {
    mock.onGet(propsData.endpoint).reply(response, body, header);
  };

  const mountWrapper = () => {
    wrapper = shallowMount(MrWidgetTerraformPlan, { propsData });
    return axios.waitForAll();
  };

  beforeEach(() => {
    mock = new MockAdapter(axios);
  });

  afterEach(() => {
    wrapper.destroy();
    mock.restore();
  });

  describe('loading poll', () => {
    beforeEach(() => {
      mockPollingApi(200, { 'tfplan.json': plan }, {});

      return mountWrapper().then(() => {
        wrapper.setData({ loading: true });
        return wrapper.vm.$nextTick();
      });
    });

    it('Diplays loading icon when loading is true', () => {
      expect(wrapper.find(GlLoadingIcon).exists()).toBe(true);

      expect(wrapper.find(GlSprintf).exists()).toBe(false);

      expect(wrapper.text()).not.toContain(
        'A terraform report was generated in your pipelines. Changes are unknown',
      );
    });
  });

  describe('successful poll', () => {
    let pollRequest;
    let pollStop;

    beforeEach(() => {
      pollRequest = jest.spyOn(Poll.prototype, 'makeRequest');
      pollStop = jest.spyOn(Poll.prototype, 'stop');

      mockPollingApi(200, { 'tfplan.json': plan }, {});

      return mountWrapper();
    });

    afterEach(() => {
      pollRequest.mockRestore();
      pollStop.mockRestore();
    });

    it('content change text', () => {
      expect(wrapper.find(GlSprintf).exists()).toBe(true);
    });

    it('renders button when url is found', () => {
      expect(wrapper.find(GlLink).exists()).toBe(true);
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

    it('does not display changes text when api fails', () => {
      expect(wrapper.text()).toContain(
        'A terraform report was generated in your pipelines. Changes are unknown',
      );

      expect(wrapper.find('.js-terraform-report-link').exists()).toBe(false);
      expect(wrapper.find(GlLink).exists()).toBe(false);
    });
  });
});
