import { GlTable, GlButton, GlPagination } from '@gitlab/ui';
import Vue from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import { GROUP_BADGE, PROJECT_BADGE } from '~/badges/constants';
import createState from '~/badges/store/state';
import mutations from '~/badges/store/mutations';
import actions from '~/badges/store/actions';
import BadgeList from '~/badges/components/badge_list.vue';
import Badge from '~/badges/components/badge.vue';
import { createDummyBadge } from '../dummy_badge';
import { MOCK_PAGINATION } from '../mock_data';

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
  const findBadge = () => wrapper.findComponent(Badge);
  const findPagination = () => wrapper.findComponent(GlPagination);

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
    it('renders a row for each badge', () => {
      createComponent({
        kind: GROUP_BADGE,
        badges,
      });

      const rows = findTable().find('tbody').findAll('tr');

      expect(rows).toHaveLength(numberOfDummyBadges);
    });

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
      expect(findBadge().props('imageUrl')).toBe(badges[0].renderedImageUrl);
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

  describe('Pagination', () => {
    describe.each`
      isLoading | nextPage | previousPage | expected
      ${true}   | ${2}     | ${null}      | ${false}
      ${true}   | ${null}  | ${1}         | ${false}
      ${true}   | ${null}  | ${null}      | ${false}
      ${false}  | ${2}     | ${null}      | ${true}
      ${false}  | ${null}  | ${1}         | ${true}
      ${false}  | ${null}  | ${null}      | ${false}
    `('template', ({ isLoading, nextPage, previousPage, expected }) => {
      beforeEach(() => {
        createComponent({
          isLoading,
          pagination: {
            ...MOCK_PAGINATION,
            nextPage,
            previousPage,
          },
        });
      });

      it(`does${expected ? '' : ' not'} render pagination when isLoading is ${isLoading}, nextPage is ${nextPage}, and previousPage is ${previousPage}`, () => {
        expect(findPagination().exists()).toBe(expected);
      });
    });

    describe('events', () => {
      beforeEach(() => {
        createComponent({
          pagination: MOCK_PAGINATION,
        });
      });

      it('calls actions.loadBadges with the correct page when @input is emitted with valid page', () => {
        findPagination().vm.$emit('input', MOCK_PAGINATION.nextPage);

        expect(mockedActions.loadBadges).toHaveBeenCalledWith(expect.any(Object), {
          page: MOCK_PAGINATION.nextPage,
        });
      });

      it('does not call actions.loadBadges when user tries to navigate before page 1', () => {
        findPagination().vm.$emit('input', 0);

        expect(mockedActions.loadBadges).not.toHaveBeenCalled();
      });

      it('does not call actions.loadBadges when user tries to navigate past the last page', () => {
        findPagination().vm.$emit('input', MOCK_PAGINATION.totalPages + 1);

        expect(mockedActions.loadBadges).not.toHaveBeenCalled();
      });
    });
  });
});
