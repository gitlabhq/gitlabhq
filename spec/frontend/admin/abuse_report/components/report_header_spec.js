import { GlAvatar, GlLink, GlButton } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import ReportHeader from '~/admin/abuse_report/components/report_header.vue';
import AbuseReportActions from '~/admin/abuse_reports/components/abuse_report_actions.vue';
import { REPORT_HEADER_I18N } from '~/admin/abuse_report/constants';
import { mockAbuseReport } from '../mock_data';

describe('ReportHeader', () => {
  let wrapper;

  const { user, actions } = mockAbuseReport;

  const findAvatar = () => wrapper.findComponent(GlAvatar);
  const findLink = () => wrapper.findComponent(GlLink);
  const findButton = () => wrapper.findComponent(GlButton);
  const findActions = () => wrapper.findComponent(AbuseReportActions);

  const createComponent = (props = {}) => {
    wrapper = shallowMount(ReportHeader, {
      propsData: {
        user,
        actions,
        ...props,
      },
    });
  };

  beforeEach(() => {
    createComponent();
  });

  it('renders the users avatar', () => {
    expect(findAvatar().props('src')).toBe(user.avatarUrl);
  });

  it('renders the users name', () => {
    expect(wrapper.html()).toContain(user.name);
  });

  it('renders a link to the users profile page', () => {
    const link = findLink();

    expect(link.attributes('href')).toBe(user.path);
    expect(link.text()).toBe(`@${user.username}`);
  });

  it('renders a button with a link to the users admin path', () => {
    const button = findButton();

    expect(button.attributes('href')).toBe(user.adminPath);
    expect(button.text()).toBe(REPORT_HEADER_I18N.adminProfile);
  });

  it('renders the actions', () => {
    const actionsComponent = findActions();

    expect(actionsComponent.props('report')).toMatchObject(actions);
  });
});
