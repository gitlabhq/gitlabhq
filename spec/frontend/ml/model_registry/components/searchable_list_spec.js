import { GlAlert } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import SearchableList from '~/ml/model_registry/components/searchable_list.vue';
import PackagesListLoader from '~/packages_and_registries/shared/components/packages_list_loader.vue';
import RegistryList from '~/packages_and_registries/shared/components/registry_list.vue';
import { defaultPageInfo } from '../mock_data';

describe('ml/model_registry/components/searchable_list.vue', () => {
  let wrapper;

  const findAlert = () => wrapper.findComponent(GlAlert);
  const findLoader = () => wrapper.findComponent(PackagesListLoader);
  const findRegistryList = () => wrapper.findComponent(RegistryList);
  const findEmptyState = () => wrapper.findByTestId('empty-state-slot');
  const findFirstRow = () => wrapper.findByTestId('element');
  const findRows = () => wrapper.findAllByTestId('element');

  const defaultProps = {
    items: ['a', 'b', 'c'],
    pageInfo: defaultPageInfo,
    isLoading: false,
    errorMessage: '',
  };

  const mountComponent = (props = {}) => {
    wrapper = shallowMountExtended(SearchableList, {
      propsData: {
        ...defaultProps,
        ...props,
      },
      stubs: {
        RegistryList,
      },
      slots: {
        'empty-state': '<div data-testid="empty-state-slot">This is empty</div>',
        item: '<div data-testid="element"></div>',
      },
    });
  };

  describe('when list is loaded and has no data', () => {
    beforeEach(() => mountComponent({ items: [] }));

    it('shows empty state', () => {
      expect(findEmptyState().text()).toBe('This is empty');
    });

    it('does not display loader', () => {
      expect(findLoader().exists()).toBe(false);
    });

    it('does not display rows', () => {
      expect(findFirstRow().exists()).toBe(false);
    });

    it('does not display registry list', () => {
      expect(findRegistryList().exists()).toBe(false);
    });

    it('does not display alert', () => {
      expect(findAlert().exists()).toBe(false);
    });
  });

  describe('if errorMessage', () => {
    beforeEach(() => mountComponent({ errorMessage: 'Failure!' }));

    it('shows error message', () => {
      expect(findAlert().text()).toContain('Failure!');
    });

    it('is not dismissible', () => {
      expect(findAlert().props('dismissible')).toBe(false);
    });

    it('is of variant danger', () => {
      expect(findAlert().attributes('variant')).toBe('danger');
    });

    it('hides loader', () => {
      expect(findLoader().exists()).toBe(false);
    });

    it('hides registry list', () => {
      expect(findRegistryList().exists()).toBe(false);
    });

    it('hides empty state', () => {
      expect(findEmptyState().exists()).toBe(false);
    });
  });

  describe('if loading', () => {
    beforeEach(() => mountComponent({ isLoading: true }));

    it('shows loader', () => {
      expect(findLoader().exists()).toBe(true);
    });

    it('hides error message', () => {
      expect(findAlert().exists()).toBe(false);
    });

    it('hides registry list', () => {
      expect(findRegistryList().exists()).toBe(false);
    });

    it('hides empty state', () => {
      expect(findEmptyState().exists()).toBe(false);
    });
  });

  describe('when list is loaded with data', () => {
    beforeEach(() => mountComponent());

    it('displays package registry list', () => {
      expect(findRegistryList().exists()).toEqual(true);
    });

    it('binds the right props', () => {
      expect(findRegistryList().props()).toMatchObject({
        items: ['a', 'b', 'c'],
        isLoading: false,
        pagination: defaultPageInfo,
        hiddenDelete: true,
      });
    });

    it('displays package version rows', () => {
      expect(findRows().exists()).toEqual(true);
      expect(findRows()).toHaveLength(3);
    });

    it('does not display loader', () => {
      expect(findLoader().exists()).toBe(false);
    });

    it('does not display empty state', () => {
      expect(findEmptyState().exists()).toBe(false);
    });
  });

  describe('when user interacts with pagination', () => {
    beforeEach(() => mountComponent());

    it('when list emits next-page emits fetchPage with correct pageInfo', () => {
      findRegistryList().vm.$emit('next-page');

      const expectedNewPageInfo = {
        after: 'eyJpZCI6IjIifQ',
        first: 30,
        last: null,
      };

      expect(wrapper.emitted('fetch-page')).toEqual([[expectedNewPageInfo]]);
    });

    it('when list emits prev-page emits fetchPage with correct pageInfo', () => {
      findRegistryList().vm.$emit('prev-page');

      const expectedNewPageInfo = {
        before: 'eyJpZCI6IjE2In0',
        first: null,
        last: 30,
      };

      expect(wrapper.emitted('fetch-page')).toEqual([[expectedNewPageInfo]]);
    });
  });
});
