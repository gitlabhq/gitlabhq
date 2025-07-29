import { nextTick } from 'vue';
import { GlDisclosureDropdown } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import GlqlActions from '~/glql/components/common/actions.vue';

describe('GlqlActions', () => {
  let wrapper;

  const findDropdown = () => wrapper.findComponent(GlDisclosureDropdown);

  const createComponent = (props = {}, provide = {}) => {
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

  it('sets correct text for dropdown', () => {
    expect(findDropdown().props('toggleText')).toBe('Embedded view options');
  });

  it.each`
    actionsCount | availableActions                                             | showCopyContents
    ${'three'}   | ${['View source', 'Copy source', 'Reload']}                  | ${false}
    ${'four'}    | ${['View source', 'Copy source', 'Copy contents', 'Reload']} | ${true}
  `(
    'passes $actionsCount items to dropdown when showCopyContents is $showCopyContents',
    ({ availableActions, showCopyContents }) => {
      createComponent({ showCopyContents });

      const items = findDropdown().props('items');
      expect(items).toHaveLength(availableActions.length);
      items.forEach((item, index) => {
        expect(item.text).toBe(availableActions[index]);
      });
    },
  );

  describe('dropdown actions', () => {
    it('emits viewSource event with title when clicked', async () => {
      createComponent({ modalTitle: 'Test Modal' });

      findDropdown().props('items')[0].action();
      await nextTick();

      expect(wrapper.emitted('viewSource').at(0)).toEqual([{ title: 'Test Modal' }]);
    });

    it('emits copySource event when clicked', async () => {
      findDropdown().props('items')[1].action();
      await nextTick();

      expect(wrapper.emitted('copySource').at(0)).toEqual([]);
    });

    it('emits copyAsGFM event when copy contents is clicked', async () => {
      createComponent({ showCopyContents: true });

      findDropdown().props('items')[2].action();
      await nextTick();

      expect(wrapper.emitted('copyAsGFM').at(0)).toEqual([]);
    });

    it('emits reload event when clicked', async () => {
      findDropdown().props('items')[2].action();
      await nextTick();

      expect(wrapper.emitted('reload').at(0)).toEqual([]);
    });
  });
});
