import { GlLink } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import MergeRequestLink from '~/analytics/analytics_dashboards/components/visualizations/data_table/merge_request_link.vue';

describe('MergeRequestLink', () => {
  let wrapper;

  const defaultProps = {
    iid: '111111',
    title: 'Merge request title',
    webUrl: 'https://gitlab.com',
    labelsCount: 10,
    userNotesCount: 15,
    approvalCount: 2,
  };

  const createWrapper = (propOverrides) => {
    wrapper = mountExtended(MergeRequestLink, {
      propsData: {
        ...defaultProps,
        ...propOverrides,
      },
    });
  };

  const findPipelineIcon = () => wrapper.findByTestId('pipeline-icon');
  const findLabelsCount = () => wrapper.findByTestId('labels-count');
  const findUserNotesCount = () => wrapper.findByTestId('user-notes-count');
  const findApprovalCount = () => wrapper.findByTestId('approval-count');

  describe('with default props', () => {
    beforeEach(() => {
      createWrapper();
    });

    it('renders the link in the MR title', () => {
      const link = wrapper.findComponent(GlLink);
      expect(link.text()).toEqual(defaultProps.title);
      expect(link.attributes('href')).toEqual(defaultProps.webUrl);
    });

    it('renders the formatted MR iid', () => {
      expect(wrapper.findByTestId('mr-iid').text()).toEqual('!111111');
    });

    it('does not render the pipeline icon', () => {
      expect(findPipelineIcon().exists()).toBe(false);
    });

    it('renders labels count', () => {
      expect(findLabelsCount().text()).toBe('10');
      expect(findLabelsCount().attributes('class')).not.toContain('gl-opacity-5');
    });

    it('renders user notes count', () => {
      expect(findUserNotesCount().text()).toBe('15');
      expect(findUserNotesCount().attributes('class')).not.toContain('gl-opacity-5');
    });

    it('renders approval count', () => {
      expect(findApprovalCount().text()).toBe('2 Approvals');
    });
  });

  it.each`
    name         | iconProps
    ${'SUCCESS'} | ${{ name: 'status_success', variant: 'success' }}
    ${'PENDING'} | ${{ name: 'status_pending', variant: 'warning' }}
    ${'FAILED'}  | ${{ name: 'status_failed', variant: 'danger' }}
  `('renders the correct icon for $name pipeline', ({ name, iconProps }) => {
    createWrapper({ pipelineStatus: { name, label: 'ariaLabel' } });
    expect(findPipelineIcon().props()).toMatchObject({
      ...iconProps,
      ariaLabel: 'ariaLabel',
    });
  });

  describe('with no counts', () => {
    beforeEach(() => {
      createWrapper({
        labelsCount: 0,
        userNotesCount: 0,
        approvalCount: 0,
      });
    });

    it('reduces label count opacity', () => {
      expect(findLabelsCount().attributes('class')).toContain('gl-opacity-5');
    });

    it('reduces user notes count opacity', () => {
      expect(findUserNotesCount().attributes('class')).toContain('gl-opacity-5');
    });

    it('does not render approvals', () => {
      expect(findApprovalCount().exists()).toBe(false);
    });
  });
});
