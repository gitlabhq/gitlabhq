import { shallowMount } from '@vue/test-utils';

import GlobalSearchDefaultItems from '~/super_sidebar/components/global_search/components/global_search_default_items.vue';
import GlobalSearchDefaultPlaces from '~/super_sidebar/components/global_search/components/global_search_default_places.vue';
import FrequentProjects from '~/super_sidebar/components/global_search/components/frequent_projects.vue';
import FrequentGroups from '~/super_sidebar/components/global_search/components/frequent_groups.vue';
import GlobalSearchDefaultIssuables from '~/super_sidebar/components/global_search/components/global_search_default_issuables.vue';
import { mockTracking } from 'helpers/tracking_helper';
import {
  FREQUENTLY_VISITED_PROJECTS_HANDLE,
  FREQUENTLY_VISITED_GROUPS_HANDLE,
} from '~/super_sidebar/components/global_search/command_palette/constants';

describe('GlobalSearchDefaultItems', () => {
  let wrapper;
  let trackingSpy;

  const createComponent = () => {
    wrapper = shallowMount(GlobalSearchDefaultItems);
  };

  const findPlaces = () => wrapper.findComponent(GlobalSearchDefaultPlaces);
  const findProjects = () => wrapper.findComponent(FrequentProjects);
  const findGroups = () => wrapper.findComponent(FrequentGroups);
  const findIssuables = () => wrapper.findComponent(GlobalSearchDefaultIssuables);
  const receivedAttrs = (wrapperInstance) => ({
    // See https://github.com/vuejs/test-utils/issues/2151.
    ...wrapperInstance.vm.$attrs,
  });

  beforeEach(() => {
    trackingSpy = mockTracking(undefined, undefined, jest.spyOn);
    createComponent();
  });

  describe('all child components can render', () => {
    it('renders the components', () => {
      expect(findPlaces().exists()).toBe(true);
      expect(findProjects().exists()).toBe(true);
      expect(findGroups().exists()).toBe(true);
      expect(findIssuables().exists()).toBe(true);
    });

    it('sets the expected props on first component', () => {
      const places = findPlaces();
      expect(receivedAttrs(places)).toEqual({});
      expect(places.classes()).toEqual([]);
    });

    it('sets the expected props on the second component onwards', () => {
      const components = [findProjects(), findGroups(), findIssuables()];
      components.forEach((component) => {
        expect(receivedAttrs(component)).toEqual({ bordered: true });
        expect(component.classes()).toEqual(['gl-mt-3']);
      });
    });
  });

  describe('when child components emit nothing-to-render', () => {
    beforeEach(() => {
      // Emit from two elements to guard against naive index-based splicing
      findPlaces().vm.$emit('nothing-to-render');
      findIssuables().vm.$emit('nothing-to-render');
    });

    it('does not render the components', () => {
      expect(findPlaces().exists()).toBe(false);
      expect(findIssuables().exists()).toBe(false);
    });

    it('sets the expected props on first component', () => {
      const projects = findProjects();
      expect(receivedAttrs(projects)).toEqual({});
      expect(projects.classes()).toEqual([]);
    });

    it('sets the expected props on the second component', () => {
      const groups = findGroups();
      expect(receivedAttrs(groups)).toEqual({ bordered: true });
      expect(groups.classes()).toEqual(['gl-mt-3']);
    });
  });

  describe('events', () => {
    it('tracks internal event on default projects component', () => {
      findProjects().vm.$emit('action', FREQUENTLY_VISITED_PROJECTS_HANDLE);

      expect(trackingSpy).toHaveBeenCalledTimes(1);
      expect(trackingSpy).toHaveBeenCalledWith(
        undefined,
        'click_frequent_project_in_command_palette',
        expect.anything(),
      );
    });

    it('tracks internal event on default group component', () => {
      findProjects().vm.$emit('action', FREQUENTLY_VISITED_GROUPS_HANDLE);

      expect(trackingSpy).toHaveBeenCalledTimes(1);
      expect(trackingSpy).toHaveBeenCalledWith(
        undefined,
        'click_frequent_group_in_command_palette',
        expect.anything(),
      );
    });
  });
});
