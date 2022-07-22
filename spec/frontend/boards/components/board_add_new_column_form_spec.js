import { GlDropdown, GlFormGroup, GlSearchBoxByType, GlSkeletonLoader } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import Vuex from 'vuex';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import BoardAddNewColumnForm from '~/boards/components/board_add_new_column_form.vue';
import defaultState from '~/boards/stores/state';
import { mockLabelList } from '../mock_data';

Vue.use(Vuex);

describe('Board card layout', () => {
  let wrapper;

  const createStore = ({ actions = {}, getters = {}, state = {} } = {}) => {
    return new Vuex.Store({
      state: {
        ...defaultState,
        ...state,
      },
      actions,
      getters,
    });
  };

  const mountComponent = ({
    loading = false,
    noneSelected = '',
    searchLabel = '',
    searchPlaceholder = '',
    selectedId,
    actions,
    slots,
  } = {}) => {
    wrapper = extendedWrapper(
      shallowMount(BoardAddNewColumnForm, {
        propsData: {
          loading,
          noneSelected,
          searchLabel,
          searchPlaceholder,
          selectedId,
        },
        slots,
        store: createStore({
          actions: {
            setAddColumnFormVisibility: jest.fn(),
            ...actions,
          },
        }),
        stubs: {
          GlDropdown,
        },
      }),
    );
  };

  afterEach(() => {
    wrapper.destroy();
  });

  const formTitle = () => wrapper.findByTestId('board-add-column-form-title').text();
  const findSearchInput = () => wrapper.find(GlSearchBoxByType);
  const findSearchLabelFormGroup = () => wrapper.find(GlFormGroup);
  const cancelButton = () => wrapper.findByTestId('cancelAddNewColumn');
  const submitButton = () => wrapper.findByTestId('addNewColumnButton');
  const findDropdown = () => wrapper.findComponent(GlDropdown);

  it('shows form title & search input', () => {
    mountComponent();

    findDropdown().vm.$emit('show');

    expect(formTitle()).toEqual(BoardAddNewColumnForm.i18n.newList);
    expect(findSearchInput().exists()).toBe(true);
  });

  it('clicking cancel hides the form', () => {
    const setAddColumnFormVisibility = jest.fn();
    mountComponent({
      actions: {
        setAddColumnFormVisibility,
      },
    });

    cancelButton().vm.$emit('click');

    expect(setAddColumnFormVisibility).toHaveBeenCalledWith(expect.anything(), false);
  });

  describe('items', () => {
    const mountWithItems = (loading) =>
      mountComponent({
        loading,
        slots: {
          items: '<div class="item-slot">Some kind of list</div>',
        },
      });

    it('hides items slot and shows skeleton while loading', () => {
      mountWithItems(true);

      expect(wrapper.findComponent(GlSkeletonLoader).exists()).toBe(true);
      expect(wrapper.find('.item-slot').exists()).toBe(false);
    });

    it('shows items slot and hides skeleton while not loading', () => {
      mountWithItems(false);

      expect(wrapper.findComponent(GlSkeletonLoader).exists()).toBe(false);
      expect(wrapper.find('.item-slot').exists()).toBe(true);
    });
  });

  describe('search box', () => {
    it('sets label and placeholder text from props', () => {
      const props = {
        searchLabel: 'Some items',
        searchPlaceholder: 'Search for an item',
      };

      mountComponent(props);

      expect(findSearchLabelFormGroup().attributes('label')).toEqual(props.searchLabel);
      expect(findSearchInput().attributes('placeholder')).toEqual(props.searchPlaceholder);
    });

    it('does not show the dropdown as invalid by default', () => {
      mountComponent();

      expect(findSearchLabelFormGroup().attributes('state')).toBe('true');
      expect(findDropdown().props('toggleClass')).not.toContain('gl-inset-border-1-red-400!');
    });

    it('emits filter event on input', () => {
      mountComponent();

      const searchText = 'some text';

      findSearchInput().vm.$emit('input', searchText);

      expect(wrapper.emitted('filter-items')).toEqual([[searchText]]);
    });
  });

  describe('Add list button', () => {
    it('is enabled by default', () => {
      mountComponent();

      expect(submitButton().props('disabled')).toBe(false);
    });

    it('emits add-list event on click when an ID is selected', () => {
      mountComponent({
        selectedId: mockLabelList.label.id,
      });

      submitButton().vm.$emit('click');

      expect(wrapper.emitted('add-list')).toEqual([[]]);
    });

    it('does not emit the add-list event on click and shows the dropdown as invalid when no ID is selected', async () => {
      mountComponent();

      await submitButton().vm.$emit('click');

      expect(findSearchLabelFormGroup().attributes('state')).toBeUndefined();
      expect(findDropdown().props('toggleClass')).toContain('gl-inset-border-1-red-400!');

      expect(wrapper.emitted('add-list')).toBeUndefined();
    });
  });
});
