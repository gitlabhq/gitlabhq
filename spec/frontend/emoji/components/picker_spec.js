import { nextTick } from 'vue';
import { shallowMount } from '@vue/test-utils';
import { GlSearchBoxByType, GlDisclosureDropdown } from '@gitlab/ui';
import EmojiPicker from '~/emoji/components/picker.vue';

describe('Emoji Picker component', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = shallowMount(EmojiPicker, {
      stubs: { GlDisclosureDropdown },
    });
  };

  const findDropdown = () => wrapper.findComponent(GlDisclosureDropdown);
  const findSearchBox = () => wrapper.findComponent(GlSearchBoxByType);
  const findCategoryButtons = () => wrapper.find('[data-testid="category-buttons"]');

  beforeEach(() => {
    createComponent();
  });

  describe('visibility handling', () => {
    it('does not render search box or category buttons when dropdown is hidden', () => {
      expect(findSearchBox().exists()).toBe(false);
      expect(findCategoryButtons().exists()).toBe(false);
    });

    it('renders search box and category buttons when dropdown is shown', async () => {
      await findDropdown().vm.$emit('shown');
      await nextTick();

      expect(findSearchBox().exists()).toBe(true);
      expect(findCategoryButtons().exists()).toBe(true);
    });

    it('hides search box and category buttons when dropdown is hidden', async () => {
      await findDropdown().vm.$emit('shown');
      await nextTick();
      await findDropdown().vm.$emit('hidden');
      await nextTick();

      expect(findSearchBox().exists()).toBe(false);
      expect(findCategoryButtons().exists()).toBe(false);
    });
  });
});
