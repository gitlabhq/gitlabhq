import { shallowMount } from '@vue/test-utils';
import HealthStatus from '~/work_items/list/components/health_status.vue';
import { WIDGET_TYPE_HEALTH_STATUS } from '~/work_items/constants';

const IssueHealthStatus = { template: '<div></div>', props: ['healthStatus'] };

describe('HealthStatus', () => {
  let wrapper;

  const issueWithHealthStatus = {
    healthStatus: 'onTrack',
  };

  const issueWithWidgetHealthStatus = {
    widgets: [
      {
        type: WIDGET_TYPE_HEALTH_STATUS,
        healthStatus: 'onTrack',
      },
    ],
  };

  const issueWithoutHealthStatus = {};

  const findIssueHealthStatus = () => wrapper.findComponent(IssueHealthStatus);

  const mountComponent = ({ issue, hasIssuableHealthStatusFeature = false } = {}) =>
    shallowMount(HealthStatus, {
      provide: { hasIssuableHealthStatusFeature },
      propsData: { issue },
      stubs: { IssueHealthStatus },
    });

  describe('when hasIssuableHealthStatusFeature=false', () => {
    it('does not render IssueHealthStatus', () => {
      wrapper = mountComponent({
        issue: issueWithHealthStatus,
        hasIssuableHealthStatusFeature: false,
      });

      expect(findIssueHealthStatus().exists()).toBe(false);
    });
  });

  describe('when hasIssuableHealthStatusFeature=true', () => {
    it('renders IssueHealthStatus when healthStatus is defined on issue', () => {
      wrapper = mountComponent({
        issue: issueWithHealthStatus,
        hasIssuableHealthStatusFeature: true,
      });

      expect(findIssueHealthStatus().props('healthStatus')).toBe('onTrack');
    });

    it('renders IssueHealthStatus when healthStatus is defined on widget', () => {
      wrapper = mountComponent({
        issue: issueWithWidgetHealthStatus,
        hasIssuableHealthStatusFeature: true,
      });

      expect(findIssueHealthStatus().props('healthStatus')).toBe('onTrack');
    });

    it('does not render IssueHealthStatus when no health status is defined', () => {
      wrapper = mountComponent({
        issue: issueWithoutHealthStatus,
        hasIssuableHealthStatusFeature: true,
      });

      expect(findIssueHealthStatus().exists()).toBe(false);
    });
  });
});
