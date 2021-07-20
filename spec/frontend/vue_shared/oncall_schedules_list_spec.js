import { GlLink, GlSprintf } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import OncallSchedulesList from '~/vue_shared/components/oncall_schedules_list.vue';

const mockSchedules = [
  {
    name: 'Schedule 1',
    scheduleUrl: 'http://gitlab.com/gitlab-org/gitlab-shell/-/oncall_schedules',
    projectName: 'Shell',
    projectUrl: 'http://gitlab.com/gitlab-org/gitlab-shell/',
  },
  {
    name: 'Schedule 2',
    scheduleUrl: 'http://gitlab.com/gitlab-org/gitlab-ui/-/oncall_schedules',
    projectName: 'UI',
    projectUrl: 'http://gitlab.com/gitlab-org/gitlab-ui/',
  },
];

const userName = "O'User";

describe('On-call schedules list', () => {
  let wrapper;

  function createComponent(props) {
    wrapper = extendedWrapper(
      shallowMount(OncallSchedulesList, {
        propsData: {
          schedules: mockSchedules,
          userName,
          ...props,
        },
        stubs: {
          GlSprintf,
        },
      }),
    );
  }

  afterEach(() => {
    wrapper.destroy();
  });

  const findLinks = () => wrapper.findAllComponents(GlLink);
  const findTitle = () => wrapper.findByTestId('title');
  const findFooter = () => wrapper.findByTestId('footer');
  const findSchedules = () => wrapper.findByTestId('schedules-list');

  describe.each`
    isCurrentUser | titleText                                   | footerText
    ${true}       | ${'You are currently a part of:'}           | ${'Removing yourself may put your on-call team at risk of missing a notification.'}
    ${false}      | ${`User ${userName} is currently part of:`} | ${'Removing this user may put their on-call team at risk of missing a notification.'}
  `('when current user ', ({ isCurrentUser, titleText, footerText }) => {
    it(`${isCurrentUser ? 'is' : 'is not'} a part of on-call schedule`, async () => {
      createComponent({
        isCurrentUser,
      });

      expect(findTitle().text()).toBe(titleText);
      expect(findFooter().text()).toBe(footerText);
    });
  });

  describe.each(mockSchedules)(
    'renders each on-call schedule data',
    ({ name, scheduleUrl, projectName, projectUrl }) => {
      beforeEach(() => {
        createComponent({ schedules: [{ name, scheduleUrl, projectName, projectUrl }] });
      });

      it(`renders schedule ${name}'s name and link`, () => {
        const msg = findSchedules().text();

        expect(msg).toContain(`On-call schedule ${name}`);
        expect(findLinks().at(0).attributes('href')).toBe(scheduleUrl);
      });

      it(`renders project ${projectName}'s name and link`, () => {
        const msg = findSchedules().text();

        expect(msg).toContain(`in Project ${projectName}`);
        expect(findLinks().at(1).attributes('href')).toBe(projectUrl);
      });
    },
  );
});
