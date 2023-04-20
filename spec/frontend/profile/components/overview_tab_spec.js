import { GlLoadingIcon, GlTab, GlLink } from '@gitlab/ui';

import projects from 'test_fixtures/api/users/projects/get.json';
import { s__ } from '~/locale';
import OverviewTab from '~/profile/components/overview_tab.vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import ActivityCalendar from '~/profile/components/activity_calendar.vue';
import ProjectsList from '~/vue_shared/components/projects_list/projects_list.vue';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';

describe('OverviewTab', () => {
  let wrapper;

  const defaultPropsData = {
    personalProjects: convertObjectPropsToCamelCase(projects, { deep: true }),
    personalProjectsLoading: false,
  };

  const createComponent = ({ propsData = {} } = {}) => {
    wrapper = shallowMountExtended(OverviewTab, {
      propsData: { ...defaultPropsData, ...propsData },
    });
  };

  it('renders `GlTab` and sets `title` prop', () => {
    createComponent();

    expect(wrapper.findComponent(GlTab).attributes('title')).toBe(s__('UserProfile|Overview'));
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
});
