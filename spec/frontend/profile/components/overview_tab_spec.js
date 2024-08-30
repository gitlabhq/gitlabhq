import { GlLoadingIcon, GlTab, GlLink } from '@gitlab/ui';
import AxiosMockAdapter from 'axios-mock-adapter';

import projects from 'test_fixtures/api/users/projects/get.json';
import events from 'test_fixtures/controller/users/activity.json';
import OverviewTab from '~/profile/components/overview_tab.vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import ActivityCalendar from '~/profile/components/activity_calendar.vue';
import ProjectsList from '~/vue_shared/components/projects_list/projects_list.vue';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import axios from '~/lib/utils/axios_utils';
import ContributionEvents from '~/contribution_events/components/contribution_events.vue';
import { createAlert } from '~/alert';
import waitForPromises from 'helpers/wait_for_promises';
import { HTTP_STATUS_OK } from '~/lib/utils/http_status';

jest.mock('~/alert');

describe('OverviewTab', () => {
  let wrapper;
  let axiosMock;

  const defaultPropsData = {
    personalProjects: convertObjectPropsToCamelCase(projects, { deep: true }),
    personalProjectsLoading: false,
  };

  const defaultProvide = { userActivityPath: '/users/root/activity.json' };

  const createComponent = ({ propsData = {} } = {}) => {
    wrapper = shallowMountExtended(OverviewTab, {
      propsData: { ...defaultPropsData, ...propsData },
      provide: defaultProvide,
    });
  };

  beforeEach(() => {
    axiosMock = new AxiosMockAdapter(axios);
  });

  afterEach(() => {
    axiosMock.restore();
  });

  it('renders `GlTab` and sets `title` prop', () => {
    createComponent();

    expect(wrapper.findComponent(GlTab).attributes('title')).toBe('Overview');
  });

  it('renders `ActivityCalendar` component', () => {
    createComponent();

    expect(wrapper.findComponent(ActivityCalendar).exists()).toBe(true);
  });

  it('renders personal projects section heading and `View all` link', () => {
    createComponent();

    expect(
      wrapper.findByRole('heading', { name: OverviewTab.i18n.personalProjects }).exists(),
    ).toBe(true);
    expect(wrapper.findComponent(GlLink).text()).toBe(OverviewTab.i18n.viewAll);
  });

  describe('when personal projects are loading', () => {
    it('renders loading icon', () => {
      createComponent({
        propsData: {
          personalProjects: [],
          personalProjectsLoading: true,
        },
      });

      expect(
        wrapper.findByTestId('personal-projects-section').findComponent(GlLoadingIcon).exists(),
      ).toBe(true);
    });
  });

  describe('when projects are done loading', () => {
    it('renders `ProjectsList` component and passes `projects` prop', () => {
      createComponent();

      expect(
        wrapper
          .findByTestId('personal-projects-section')
          .findComponent(ProjectsList)
          .props('projects'),
      ).toMatchObject(defaultPropsData.personalProjects);
    });
  });

  describe('when activity API request is loading', () => {
    beforeEach(() => {
      axiosMock.onGet(defaultProvide.userActivityPath).reply(HTTP_STATUS_OK, events);

      createComponent();
    });

    it('shows loading icon', () => {
      expect(wrapper.findByTestId('activity-section').findComponent(GlLoadingIcon).exists()).toBe(
        true,
      );
    });
  });

  describe('when activity API request is successful', () => {
    beforeEach(() => {
      axiosMock.onGet(defaultProvide.userActivityPath).reply(HTTP_STATUS_OK, events);

      createComponent();
    });

    it('renders `ContributionEvents` component', async () => {
      await waitForPromises();

      expect(wrapper.findComponent(ContributionEvents).props('events')).toEqual(events);
    });
  });

  describe('when activity API request is not successful', () => {
    beforeEach(() => {
      axiosMock.onGet(defaultProvide.userActivityPath).networkError();

      createComponent();
    });

    it('calls `createAlert`', async () => {
      await waitForPromises();

      expect(createAlert).toHaveBeenCalledWith({
        message: OverviewTab.i18n.eventsErrorMessage,
        error: new Error('Network Error'),
        captureError: true,
      });
    });
  });
});
