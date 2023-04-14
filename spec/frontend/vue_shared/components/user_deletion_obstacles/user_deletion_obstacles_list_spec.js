import { GlLink, GlSprintf } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import { OBSTACLE_TYPES } from '~/vue_shared/components/user_deletion_obstacles/constants';
import UserDeletionObstaclesList from '~/vue_shared/components/user_deletion_obstacles/user_deletion_obstacles_list.vue';

const mockSchedules = [
  {
    type: OBSTACLE_TYPES.oncallSchedules,
    name: 'Schedule 1',
    url: 'http://gitlab.com/gitlab-org/gitlab-shell/-/oncall_schedules',
    projectName: 'Shell',
    projectUrl: 'http://gitlab.com/gitlab-org/gitlab-shell/',
  },
  {
    type: OBSTACLE_TYPES.oncallSchedules,
    name: 'Schedule 2',
    url: 'http://gitlab.com/gitlab-org/gitlab-ui/-/oncall_schedules',
    projectName: 'UI',
    projectUrl: 'http://gitlab.com/gitlab-org/gitlab-ui/',
  },
];
const mockPolicies = [
  {
    type: OBSTACLE_TYPES.escalationPolicies,
    name: 'Policy 1',
    url: 'http://gitlab.com/gitlab-org/gitlab-ui/-/escalation-policies',
    projectName: 'UI',
    projectUrl: 'http://gitlab.com/gitlab-org/gitlab-ui/',
  },
];
const mockObstacles = mockSchedules.concat(mockPolicies);

const userName = "O'User";

describe('User deletion obstacles list', () => {
  let wrapper;

  function createComponent(props) {
    wrapper = extendedWrapper(
      shallowMount(UserDeletionObstaclesList, {
        propsData: {
          obstacles: mockObstacles,
          userName,
          ...props,
        },
        stubs: {
          GlSprintf,
        },
      }),
    );
  }

  const findLinks = () => wrapper.findAllComponents(GlLink);
  const findTitle = () => wrapper.findByTestId('title');
  const findFooter = () => wrapper.findByTestId('footer');
  const findObstacles = () => wrapper.findByTestId('obstacles-list');

  describe.each`
    isCurrentUser | titleText                                   | footerText
    ${true}       | ${'You are currently a part of:'}           | ${'Removing yourself may put your on-call team at risk of missing a notification.'}
    ${false}      | ${`User ${userName} is currently part of:`} | ${'Removing this user may put their on-call team at risk of missing a notification.'}
  `('when current user', ({ isCurrentUser, titleText, footerText }) => {
    it(`${isCurrentUser ? 'is' : 'is not'} a part of on-call management`, () => {
      createComponent({
        isCurrentUser,
      });

      expect(findTitle().text()).toBe(titleText);
      expect(findFooter().text()).toBe(footerText);
    });
  });

  describe.each(mockObstacles)(
    'renders all obstacles',
    ({ type, name, url, projectName, projectUrl }) => {
      it(`includes the project name and link for ${name}`, () => {
        createComponent({ obstacles: [{ type, name, url, projectName, projectUrl }] });
        const msg = findObstacles().text();

        expect(msg).toContain(`in project ${projectName}`);
        expect(findLinks().at(1).attributes('href')).toBe(projectUrl);
      });
    },
  );

  describe.each(mockSchedules)(
    'renders on-call schedules',
    ({ type, name, url, projectName, projectUrl }) => {
      it(`includes the schedule name and link for ${name}`, () => {
        createComponent({ obstacles: [{ type, name, url, projectName, projectUrl }] });
        const msg = findObstacles().text();

        expect(msg).toContain(`On-call schedule ${name}`);
        expect(findLinks().at(0).attributes('href')).toBe(url);
      });
    },
  );

  describe.each(mockPolicies)(
    'renders escalation policies',
    ({ type, name, url, projectName, projectUrl }) => {
      it(`includes the policy name and link for ${name}`, () => {
        createComponent({ obstacles: [{ type, name, url, projectName, projectUrl }] });
        const msg = findObstacles().text();

        expect(msg).toContain(`Escalation policy ${name}`);
        expect(findLinks().at(0).attributes('href')).toBe(url);
      });
    },
  );
});
