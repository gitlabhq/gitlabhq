import { nextTick } from 'vue';
import { GlDisclosureDropdown } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import GlqlActions from '~/glql/components/common/actions.vue';
import { eventHubByKey } from '~/glql/utils/event_hub_factory';

jest.mock('~/glql/utils/event_hub_factory');

describe('GlqlActions', () => {
  let wrapper;
  let mockEventHub;

  const findDropdown = () => wrapper.findComponent(GlDisclosureDropdown);

  const createComponent = (props = {}, provide = {}) => {
    mockEventHub = {
      $emit: jest.fn(),
    };

    eventHubByKey.mockReturnValue(mockEventHub);

    wrapper = mountExtended(GlqlActions, {
      propsData: {
        ...props,
      },
      provide: {
        queryKey: 'test-key',
        ...provide,
      },
    });
  };

  beforeEach(() => {
    createComponent();
  });

  it('renders the dropdown component', () => {
    expect(findDropdown().exists()).toBe(true);
  });

  it('sets correct tooltip and text for dropdown', () => {
    expect(findDropdown().attributes('title')).toBe('GLQL view options');
    expect(findDropdown().props('toggleText')).toBe('GLQL view options');
  });

  it('passes two items to dropdown when showCopyContents is false', () => {
    createComponent({ showCopyContents: false });

    const items = findDropdown().props('items');
    expect(items).toHaveLength(2);
    expect(items[0].text).toBe('View source');
    expect(items[1].text).toBe('Copy source');
  });

  it('passes three items to dropdown when showCopyContents is true', () => {
    createComponent({ showCopyContents: true });

    const items = findDropdown().props('items');
    expect(items).toHaveLength(3);
    expect(items[0].text).toBe('View source');
    expect(items[1].text).toBe('Copy source');
    expect(items[2].text).toBe('Copy contents');
  });

  describe('dropdown actions', () => {
    it('emits viewSource event with title when clicked', async () => {
      createComponent({ modalTitle: 'Test Modal' });

      findDropdown().props('items')[0].action();
      await nextTick();

      expect(mockEventHub.$emit).toHaveBeenCalledWith('dropdownAction', 'viewSource', {
        title: 'Test Modal',
      });
    });

    it('emits copySource event when clicked', async () => {
      findDropdown().props('items')[1].action();
      await nextTick();

      expect(mockEventHub.$emit).toHaveBeenCalledWith('dropdownAction', 'copySource');
    });

    it('emits copyAsGFM event when copy contents is clicked', async () => {
      createComponent({ showCopyContents: true });

      findDropdown().props('items')[2].action();
      await nextTick();

      expect(mockEventHub.$emit).toHaveBeenCalledWith('dropdownAction', 'copyAsGFM');
    });
  });
});
