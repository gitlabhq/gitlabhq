import { GlTable, GlButton } from '@gitlab/ui';
import Vue from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import { GROUP_BADGE, PROJECT_BADGE } from '~/badges/constants';
import createState from '~/badges/store/state';
import mutations from '~/badges/store/mutations';
import actions from '~/badges/store/actions';
import BadgeList from '~/badges/components/badge_list.vue';
import { createDummyBadge } from '../dummy_badge';

Vue.use(Vuex);

const numberOfDummyBadges = 3;
const badges = Array.from({ length: numberOfDummyBadges }).map((_, idx) => ({
  ...createDummyBadge(),
  id: idx,
}));

describe('BadgeList component', () => {
  let wrapper;
  let mockedActions;

  const findTable = () => wrapper.findComponent(GlTable);
  const findTableRow = (pos) => findTable().find('tbody').findAll('tr').at(pos);
  const findButtons = () => wrapper.findByTestId('badge-actions').findAllComponents(GlButton);
  const findEditButton = () => wrapper.findByTestId('edit-badge-button');
  const findDeleteButton = () => wrapper.findByTestId('delete-badge');

  const createComponent = (customState) => {
    mockedActions = Object.fromEntries(Object.keys(actions).map((name) => [name, jest.fn()]));

    const store = new Vuex.Store({
      state: {
        ...createState(),
        isLoading: false,
        ...customState,
      },
      mutations,
      actions: mockedActions,
    });

    wrapper = mountExtended(BadgeList, {
      store,
      stubs: {
        GlTable,
        GlButton,
      },
    });
  };

  describe('for project badges', () => {
    it('renders a row for each badge', () => {
      createComponent({
        kind: PROJECT_BADGE,
        badges,
      });

      const rows = findTable().find('tbody').findAll('tr');

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

  describe('BadgeList item', () => {
    beforeEach(() => {
      createComponent({
        kind: PROJECT_BADGE,
        badges,
      });
    });

    it('renders the badge', () => {
      const badgeImage = wrapper.find('.project-badge');

      expect(badgeImage.exists()).toBe(true);
      expect(badgeImage.attributes('src')).toBe(badges[0].renderedImageUrl);
    });

    it('renders the badge name', () => {
      const badgeCell = findTableRow(0).findAll('td').at(0);

      expect(badgeCell.text()).toMatch(badges[0].name);
    });

    it('renders the badge link', () => {
      expect(wrapper.text()).toMatch(badges[0].linkUrl);
    });

    it('renders the badge kind', () => {
      expect(wrapper.text()).toMatch('Project Badge');
    });

    it('shows edit and delete buttons', () => {
      expect(findButtons()).toHaveLength(2);

      const editButton = findEditButton();

      expect(editButton.isVisible()).toBe(true);
      expect(editButton.element).toHaveSpriteIcon('pencil');

      const deleteButton = findDeleteButton();

      expect(deleteButton.isVisible()).toBe(true);
      expect(deleteButton.element).toHaveSpriteIcon('remove');
    });

    it('calls editBadge when clicking then edit button', () => {
      findEditButton().trigger('click');

      expect(mockedActions.editBadge).toHaveBeenCalled();
    });

    it('calls updateBadgeInModal and shows modal when clicking then delete button', () => {
      findDeleteButton().trigger('click');

      expect(mockedActions.updateBadgeInModal).toHaveBeenCalled();
    });
  });
});
