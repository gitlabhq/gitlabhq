import { shallowMount } from '@vue/test-utils';
import { trimText } from 'helpers/text_helper';
import frequentItemsListItemComponent from '~/frequent_items/components/frequent_items_list_item.vue';
import { mockProject } from '../mock_data'; // can also use 'mockGroup', but not useful to test here

describe('FrequentItemsListItemComponent', () => {
  let wrapper;

  const findTitle = () => wrapper.find({ ref: 'frequentItemsItemTitle' });
  const findAvatar = () => wrapper.find({ ref: 'frequentItemsItemAvatar' });
  const findAllTitles = () => wrapper.findAll({ ref: 'frequentItemsItemTitle' });
  const findNamespace = () => wrapper.find({ ref: 'frequentItemsItemNamespace' });
  const findAllAnchors = () => wrapper.findAll('a');
  const findAllNamespace = () => wrapper.findAll({ ref: 'frequentItemsItemNamespace' });
  const findAvatarContainer = () => wrapper.findAll({ ref: 'frequentItemsItemAvatarContainer' });
  const findAllMetadataContainers = () =>
    wrapper.findAll({ ref: 'frequentItemsItemMetadataContainer' });

  const createComponent = (props = {}) => {
    wrapper = shallowMount(frequentItemsListItemComponent, {
      propsData: {
        itemId: mockProject.id,
        itemName: mockProject.name,
        namespace: mockProject.namespace,
        webUrl: mockProject.webUrl,
        avatarUrl: mockProject.avatarUrl,
        ...props,
      },
    });
  };

  afterEach(() => {
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

    it('should render avatar if avatarUrl is present', () => {
      wrapper.setProps({ avatarUrl: 'path/to/avatar.png' });

      return wrapper.vm.$nextTick(() => {
        expect(findAvatar().exists()).toBe(true);
      });
    });

    it('should not render avatar if avatarUrl is not present', () => {
      expect(findAvatar().exists()).toBe(false);
    });

    it('renders root element with the right classes', () => {
      expect(wrapper.classes('frequent-items-list-item-container')).toBe(true);
    });

    it.each`
      name                    | selector                     | expected
      ${'anchor'}             | ${findAllAnchors}            | ${1}
      ${'avatar container'}   | ${findAvatarContainer}       | ${1}
      ${'metadata container'} | ${findAllMetadataContainers} | ${1}
      ${'title'}              | ${findAllTitles}             | ${1}
      ${'namespace'}          | ${findAllNamespace}          | ${1}
    `('should render $expected $name', ({ selector, expected }) => {
      expect(selector()).toHaveLength(expected);
    });
  });
});
