import Vue from 'vue';
import Vuex from 'vuex';
import { mount } from '@vue/test-utils';

import BadgeList from '~/badges/components/badge_list.vue';
import { GROUP_BADGE, PROJECT_BADGE } from '~/badges/constants';

import createState from '~/badges/store/state';
import mutations from '~/badges/store/mutations';
import actions from '~/badges/store/actions';

import { createDummyBadge } from '../dummy_badge';

Vue.use(Vuex);

const numberOfDummyBadges = 3;
const badges = Array.from({ length: numberOfDummyBadges }).map((_, idx) => ({
  ...createDummyBadge(),
  id: idx,
}));

describe('BadgeList component', () => {
  let wrapper;

  const createComponent = (customState) => {
    const mockedActions = Object.fromEntries(Object.keys(actions).map((name) => [name, jest.fn()]));

    const store = new Vuex.Store({
      state: {
        ...createState(),
        isLoading: false,
        ...customState,
      },
      mutations,
      actions: mockedActions,
    });

    wrapper = mount(BadgeList, { store });
  };

  describe('for project badges', () => {
    it('renders a header with the badge count', () => {
      createComponent({
        kind: PROJECT_BADGE,
        badges,
      });

      const header = wrapper.find('.card-header');

      expect(header.text()).toMatchInterpolatedText('Your badges 3');
    });

    it('renders a row for each badge', () => {
      createComponent({
        kind: PROJECT_BADGE,
        badges,
      });

      const rows = wrapper.findAll('.gl-responsive-table-row');

      expect(rows).toHaveLength(numberOfDummyBadges);
    });

    it('renders a message if no badges exist', () => {
      createComponent({
        kind: PROJECT_BADGE,
        badges: [],
      });

      expect(wrapper.text()).toMatch('This project has no badges');
    });

    it('shows a loading icon when loading', () => {
      createComponent({ isLoading: true });

      const loadingIcon = wrapper.find('.gl-spinner');

      expect(loadingIcon.isVisible()).toBe(true);
    });
  });

  describe('for group badges', () => {
    it('renders a message if no badges exist', () => {
      createComponent({
        kind: GROUP_BADGE,
        badges: [],
      });

      expect(wrapper.text()).toMatch('This group has no badges');
    });
  });
});
