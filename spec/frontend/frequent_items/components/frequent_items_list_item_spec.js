import { GlButton } from '@gitlab/ui';
import { shallowMount, createLocalVue } from '@vue/test-utils';
import Vuex from 'vuex';
import { trimText } from 'helpers/text_helper';
import { mockTracking, unmockTracking } from 'helpers/tracking_helper';
import frequentItemsListItemComponent from '~/frequent_items/components/frequent_items_list_item.vue';
import { createStore } from '~/frequent_items/store';
import ProjectAvatar from '~/vue_shared/components/project_avatar.vue';
import { mockProject } from '../mock_data';

const localVue = createLocalVue();
localVue.use(Vuex);

describe('FrequentItemsListItemComponent', () => {
  let wrapper;
  let trackingSpy;
  let store;

  const findTitle = () => wrapper.find({ ref: 'frequentItemsItemTitle' });
  const findAvatar = () => wrapper.findComponent(ProjectAvatar);
  const findAllTitles = () => wrapper.findAll({ ref: 'frequentItemsItemTitle' });
  const findNamespace = () => wrapper.find({ ref: 'frequentItemsItemNamespace' });
  const findAllButtons = () => wrapper.findAllComponents(GlButton);
  const findAllNamespace = () => wrapper.findAll({ ref: 'frequentItemsItemNamespace' });
  const findAllAvatars = () => wrapper.findAllComponents(ProjectAvatar);
  const findAllMetadataContainers = () =>
    wrapper.findAll({ ref: 'frequentItemsItemMetadataContainer' });

  const createComponent = (props = {}) => {
    wrapper = shallowMount(frequentItemsListItemComponent, {
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
        vuexModule: 'frequentProjects',
      },
      localVue,
    });
  };

  beforeEach(() => {
    store = createStore();
    trackingSpy = mockTracking('_category_', document, jest.spyOn);
    trackingSpy.mockImplementation(() => {});
  });

  afterEach(() => {
    unmockTracking();
    wrapper.destroy();
    wrapper = null;
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
      ${'button'}             | ${findAllButtons}            | ${1}
      ${'avatar container'}   | ${findAllAvatars}            | ${1}
      ${'metadata container'} | ${findAllMetadataContainers} | ${1}
      ${'title'}              | ${findAllTitles}             | ${1}
      ${'namespace'}          | ${findAllNamespace}          | ${1}
    `('should render $expected $name', ({ selector, expected }) => {
      expect(selector()).toHaveLength(expected);
    });

    it('tracks when item link is clicked', () => {
      const link = wrapper.findComponent(GlButton);

      link.vm.$emit('click');

      expect(trackingSpy).toHaveBeenCalledWith(undefined, 'click_link', {
        label: 'projects_dropdown_frequent_items_list_item',
      });
    });
  });
});
