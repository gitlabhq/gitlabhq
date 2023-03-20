import { GlIcon } from '@gitlab/ui';
import Vue, { nextTick } from 'vue';
import Vuex from 'vuex';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { trimText } from 'helpers/text_helper';
import { mockTracking, unmockTracking } from 'helpers/tracking_helper';
import frequentItemsListItemComponent from '~/frequent_items/components/frequent_items_list_item.vue';
import { createStore } from '~/frequent_items/store';
import ProjectAvatar from '~/vue_shared/components/project_avatar.vue';
import { mockProject } from '../mock_data';

Vue.use(Vuex);

describe('FrequentItemsListItemComponent', () => {
  const TEST_VUEX_MODULE = 'frequentProjects';
  let wrapper;
  let trackingSpy;
  let store;

  const findTitle = () => wrapper.findByTestId('frequent-items-item-title');
  const findAvatar = () => wrapper.findComponent(ProjectAvatar);
  const findAllTitles = () => wrapper.findAllByTestId('frequent-items-item-title');
  const findNamespace = () => wrapper.findByTestId('frequent-items-item-namespace');
  const findAllFrequentItems = () => wrapper.findAllByTestId('frequent-item-link');
  const findAllNamespace = () => wrapper.findAllByTestId('frequent-items-item-namespace');
  const findAllAvatars = () => wrapper.findAllComponents(ProjectAvatar);
  const findAllMetadataContainers = () =>
    wrapper.findAllByTestId('frequent-items-item-metadata-container');
  const findRemoveButton = () => wrapper.findByTestId('item-remove');

  const toggleItemsListEditablity = async () => {
    store.dispatch(`${TEST_VUEX_MODULE}/toggleItemsListEditablity`);

    await nextTick();
  };

  const createComponent = (props = {}) => {
    wrapper = shallowMountExtended(frequentItemsListItemComponent, {
      store,
      propsData: {
        itemId: mockProject.id,
        itemName: mockProject.name,
        namespace: mockProject.namespace,
        webUrl: mockProject.webUrl,
        avatarUrl: mockProject.avatarUrl,
        ...props,
      },
      provide: {
        vuexModule: TEST_VUEX_MODULE,
      },
    });
  };

  beforeEach(() => {
    store = createStore();
    trackingSpy = mockTracking('_category_', document, jest.spyOn);
    trackingSpy.mockImplementation(() => {});
  });

  afterEach(() => {
    unmockTracking();
  });

  describe('computed', () => {
    describe('highlightedItemName', () => {
      it('should enclose part of project name in <b> & </b> which matches with `matcher` prop', () => {
        createComponent({ matcher: 'lab' });

        expect(findTitle().element.innerHTML).toContain('<b>L</b><b>a</b><b>b</b>');
      });

      it('should return project name as it is if `matcher` is not available', () => {
        createComponent({ matcher: null });

        expect(trimText(findTitle().text())).toBe(mockProject.name);
      });
    });

    describe('truncatedNamespace', () => {
      it('should truncate project name from namespace string', () => {
        createComponent({ namespace: 'platform / nokia-3310' });

        expect(trimText(findNamespace().text())).toBe('platform');
      });

      it('should truncate namespace string from the middle if it includes more than two groups in path', () => {
        createComponent({
          namespace: 'platform / hardware / broadcom / Wifi Group / Mobile Chipset / nokia-3310',
        });

        expect(trimText(findNamespace().text())).toBe('platform / ... / Mobile Chipset');
      });
    });
  });

  describe('template', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders avatar', () => {
      expect(findAvatar().exists()).toBe(true);
    });

    it('renders root element with the right classes', () => {
      expect(wrapper.classes('frequent-items-list-item-container')).toBe(true);
    });

    it.each`
      name                    | selector                     | expected
      ${'list item'}          | ${findAllFrequentItems}      | ${1}
      ${'avatar container'}   | ${findAllAvatars}            | ${1}
      ${'metadata container'} | ${findAllMetadataContainers} | ${1}
      ${'title'}              | ${findAllTitles}             | ${1}
      ${'namespace'}          | ${findAllNamespace}          | ${1}
    `('should render $expected $name', ({ selector, expected }) => {
      expect(selector()).toHaveLength(expected);
    });

    it('renders remove button within item when `isItemsListEditable` is true', async () => {
      await toggleItemsListEditablity();

      const removeButton = findRemoveButton();
      expect(removeButton.exists()).toBe(true);
      expect(removeButton.attributes('title')).toBe('Remove');
      expect(removeButton.findComponent(GlIcon).props('name')).toBe('close');
    });

    it('dispatches action `removeFrequentItem` when remove button is clicked', async () => {
      await toggleItemsListEditablity();

      jest.spyOn(store, 'dispatch');

      const removeButton = findRemoveButton();
      removeButton.vm.$emit(
        'click',
        { stopPropagation: jest.fn(), preventDefault: jest.fn() },
        mockProject.id,
      );

      await nextTick();

      expect(store.dispatch).toHaveBeenCalledWith(
        `${TEST_VUEX_MODULE}/removeFrequentItem`,
        mockProject.id,
      );
    });

    it('tracks when item link is clicked', () => {
      const link = wrapper.findByTestId('frequent-item-link');

      link.vm.$emit('click');

      expect(trackingSpy).toHaveBeenCalledWith(undefined, 'click_link', {
        label: 'projects_dropdown_frequent_items_list_item',
        property: 'navigation_top',
      });
    });
  });
});
