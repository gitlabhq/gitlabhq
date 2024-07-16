import { GlBadge, GlAvatar, GlLink, GlButton } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import ReportHeader from '~/admin/abuse_report/components/report_header.vue';
import ReportActions from '~/admin/abuse_report/components/report_actions.vue';
import { REPORT_HEADER_I18N, STATUS_OPEN, STATUS_CLOSED } from '~/admin/abuse_report/constants';
import { mockAbuseReport } from '../mock_data';

describe('ReportHeader', () => {
  let wrapper;

  const { user, report } = mockAbuseReport;

  const findBadge = () => wrapper.findComponent(GlBadge);
  const findAvatar = () => wrapper.findComponent(GlAvatar);
  const findLink = () => wrapper.findComponent(GlLink);
  const findButton = () => wrapper.findComponent(GlButton);
  const findActions = () => wrapper.findComponent(ReportActions);

  const createComponent = (props = {}) => {
    wrapper = shallowMount(ReportHeader, {
      propsData: {
        user,
        report,
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

  describe.each`
    status           | text                                 | variant      | badgeIcon
    ${STATUS_OPEN}   | ${REPORT_HEADER_I18N[STATUS_OPEN]}   | ${'success'} | ${'issues'}
    ${STATUS_CLOSED} | ${REPORT_HEADER_I18N[STATUS_CLOSED]} | ${'info'}    | ${'issue-closed'}
  `('rendering the report $status status badge', ({ status, text, variant, badgeIcon }) => {
    beforeEach(() => {
      createComponent({ report: { ...report, status } });
    });

    it(`indicates the ${status} status`, () => {
      expect(findBadge().text()).toBe(text);
    });

    it(`with the ${variant} variant`, () => {
      expect(findBadge().props('variant')).toBe(variant);
    });

    it(`with the text '${text}' as 'aria-label'`, () => {
      expect(findBadge().attributes('aria-label')).toBe(text);
    });

    it(`has an icon with the ${badgeIcon} name`, () => {
      expect(findBadge().props('icon')).toBe(badgeIcon);
    });
  });

  it('renders the actions', () => {
    const actionsComponent = findActions();

    expect(actionsComponent.props('report')).toMatchObject(report);
  });
});
