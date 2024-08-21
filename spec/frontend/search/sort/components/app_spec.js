import { GlButtonGroup, GlButton, GlCollapsibleListbox, GlListboxItem } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import { MOCK_QUERY, MOCK_SORT_OPTIONS } from 'jest/search/mock_data';
import GlobalSearchSort from '~/search/sort/components/app.vue';
import { SORT_DIRECTION_UI } from '~/search/sort/constants';

Vue.use(Vuex);

describe('GlobalSearchSort', () => {
  let wrapper;

  const actionSpies = {
    setQuery: jest.fn(),
    applyQuery: jest.fn(),
  };

  const defaultProps = {
    searchSortOptions: MOCK_SORT_OPTIONS,
  };

  const createComponent = (initialState, props) => {
    const store = new Vuex.Store({
      state: {
        query: MOCK_QUERY,
        ...initialState,
      },
      actions: actionSpies,
    });

    wrapper = shallowMount(GlobalSearchSort, {
      store,
      propsData: {
        ...defaultProps,
        ...props,
      },
      stubs: {
        GlCollapsibleListbox,
      },
    });
  };

  const findSortButtonGroup = () => wrapper.findComponent(GlButtonGroup);
  const findSortDropdown = () => wrapper.findComponent(GlCollapsibleListbox);
  const findSortDirectionButton = () => wrapper.findComponent(GlButton);
  const findDropdownItems = () => findSortDropdown().findAllComponents(GlListboxItem);
  const findDropdownItemsText = () => findDropdownItems().wrappers.map((w) => w.text());

  describe('template', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders Sort Button Group', () => {
      expect(findSortButtonGroup().exists()).toBe(true);
    });

    it('renders Sort Dropdown', () => {
      expect(findSortDropdown().exists()).toBe(true);
    });

    it('renders Sort Direction Button', () => {
      expect(findSortDirectionButton().exists()).toBe(true);
    });
  });

  describe('Sort Dropdown Items', () => {
    describe('renders', () => {
      beforeEach(() => {
        createComponent();
      });

      it('an instance for each namespace', () => {
        expect(findDropdownItemsText()).toStrictEqual(
          MOCK_SORT_OPTIONS.map((option) => option.title),
        );
      });
    });

    describe.each`
      sortQuery                              | value
      ${null}                                | ${MOCK_SORT_OPTIONS[0].title}
      ${'asdf'}                              | ${MOCK_SORT_OPTIONS[0].title}
      ${MOCK_SORT_OPTIONS[0].sortParam}      | ${MOCK_SORT_OPTIONS[0].title}
      ${MOCK_SORT_OPTIONS[1].sortParam.desc} | ${MOCK_SORT_OPTIONS[1].title}
      ${MOCK_SORT_OPTIONS[1].sortParam.asc}  | ${MOCK_SORT_OPTIONS[1].title}
    `('selected', ({ sortQuery, value }) => {
      describe(`when sort option is ${sortQuery}`, () => {
        beforeEach(() => {
          createComponent({ query: { sort: sortQuery } });
        });

        it('is set correctly', () => {
          expect(findSortDropdown().props('toggleText')).toBe(value);
        });
      });
    });
  });

  describe.each`
    description              | sortQuery                              | sortUi                        | disabled
    ${'non-sortable'}        | ${MOCK_SORT_OPTIONS[0].sortParam}      | ${SORT_DIRECTION_UI.disabled} | ${'true'}
    ${'descending sortable'} | ${MOCK_SORT_OPTIONS[1].sortParam.desc} | ${SORT_DIRECTION_UI.desc}     | ${undefined}
    ${'ascending sortable'}  | ${MOCK_SORT_OPTIONS[1].sortParam.asc}  | ${SORT_DIRECTION_UI.asc}      | ${undefined}
  `('Sort Direction Button', ({ description, sortQuery, sortUi, disabled }) => {
    describe(`when sort option is ${description}`, () => {
      beforeEach(() => {
        createComponent({ query: { sort: sortQuery } });
      });

      it('sets the UI correctly', () => {
        expect(findSortDirectionButton().attributes().disabled).toBe(disabled);
        expect(findSortDirectionButton().attributes('title')).toBe(sortUi.tooltip);
        expect(findSortDirectionButton().attributes('icon')).toBe(sortUi.icon);
      });
    });
  });

  describe('actions', () => {
    describe.each`
      description       | text                          | value
      ${'non-sortable'} | ${MOCK_SORT_OPTIONS[0].title} | ${MOCK_SORT_OPTIONS[0].sortParam}
      ${'sortable'}     | ${MOCK_SORT_OPTIONS[1].title} | ${MOCK_SORT_OPTIONS[1].sortParam.desc}
    `('handleSortChange', ({ description, text, value }) => {
      describe(`when selecting a ${description} option`, () => {
        beforeEach(() => {
          createComponent();
          findSortDropdown().vm.$emit('select', text);
        });

        it('calls setQuery and applyQuery correctly', () => {
          expect(actionSpies.setQuery).toHaveBeenCalledTimes(1);
          expect(actionSpies.applyQuery).toHaveBeenCalledTimes(1);
          expect(actionSpies.setQuery).toHaveBeenCalledWith(expect.any(Object), {
            key: 'sort',
            value,
          });
        });
      });
    });

    describe.each`
      description     | sortQuery                              | value
      ${'descending'} | ${MOCK_SORT_OPTIONS[1].sortParam.desc} | ${MOCK_SORT_OPTIONS[1].sortParam.asc}
      ${'ascending'}  | ${MOCK_SORT_OPTIONS[1].sortParam.asc}  | ${MOCK_SORT_OPTIONS[1].sortParam.desc}
    `('handleSortDirectionChange', ({ description, sortQuery, value }) => {
      describe(`when toggling a ${description} option`, () => {
        beforeEach(() => {
          createComponent({ query: { sort: sortQuery } });
          findSortDirectionButton().vm.$emit('click');
        });

        it('calls setQuery and applyQuery correctly', () => {
          expect(actionSpies.setQuery).toHaveBeenCalledTimes(1);
          expect(actionSpies.applyQuery).toHaveBeenCalledTimes(1);
          expect(actionSpies.setQuery).toHaveBeenCalledWith(expect.any(Object), {
            key: 'sort',
            value,
          });
        });
      });
    });
  });
});
