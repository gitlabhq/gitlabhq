import { nextTick } from 'vue';
import { shallowMount } from '@vue/test-utils';
import { GlSearchBoxByType, GlDisclosureDropdown } from '@gitlab/ui';
import { stubComponent } from 'helpers/stub_component';
import EmojiPicker from '~/emoji/components/picker.vue';

describe('Emoji Picker component', () => {
  let wrapper;

  const createComponent = (
    { newCustomEmojiPath = '', customEmojiPath = '', ...rest } = {},
    stubs = {},
  ) => {
    wrapper = shallowMount(EmojiPicker, {
      stubs: { GlDisclosureDropdown, ...stubs },
      provide: {
        newCustomEmojiPath,
      },
      propsData: {
        customEmojiPath,
        ...rest,
      },
    });
  };

  const findDropdown = () => wrapper.findComponent(GlDisclosureDropdown);
  const findSearchBox = () => wrapper.findComponent(GlSearchBoxByType);
  const findCategoryButtons = () => wrapper.find('[data-testid="category-buttons"]');
  const findCreateNewEmojiLink = () => wrapper.find('[data-testid="create-new-emoji"]');
  const findReactionToggle = () => wrapper.find('[data-testid="add-reaction-button"]');

  const showDropdown = async () => {
    await findDropdown().vm.$emit('shown');
    await nextTick();
  };

  it('passes down toggleCategory', () => {
    createComponent(
      { toggleCategory: 'tertiary' },
      {
        GlDisclosureDropdown: stubComponent(GlDisclosureDropdown, {
          template: '<div><slot name="toggle"></slot></div>',
        }),
      },
    );
    expect(findReactionToggle().props('category')).toBe('tertiary');
  });

  describe('visibility handling', () => {
    it('does not render search box or category buttons when dropdown is hidden', () => {
      createComponent();
      expect(findSearchBox().exists()).toBe(false);
      expect(findCategoryButtons().exists()).toBe(false);
    });

    it('renders search box and category buttons when dropdown is shown', async () => {
      createComponent();
      await showDropdown();

      expect(findSearchBox().exists()).toBe(true);
      expect(findCategoryButtons().exists()).toBe(true);
    });

    it('hides search box and category buttons when dropdown is hidden', async () => {
      createComponent();
      await showDropdown();
      await findDropdown().vm.$emit('hidden');
      await nextTick();

      expect(findSearchBox().exists()).toBe(false);
      expect(findCategoryButtons().exists()).toBe(false);
    });
  });

  describe('create new emoji link', () => {
    const mockCustomEmojiPath = '/groups/gitlab-org/-/custom_emoji/new';

    it('shown when newCustomEmojiPath is provided', async () => {
      createComponent({ newCustomEmojiPath: mockCustomEmojiPath });

      await showDropdown();

      expect(findCreateNewEmojiLink().exists()).toBe(true);
      expect(findCreateNewEmojiLink().attributes('href')).toBe(mockCustomEmojiPath);
    });

    it('shown when customEmojiPath prop is set', async () => {
      createComponent({ customEmojiPath: mockCustomEmojiPath });

      await showDropdown();

      expect(findCreateNewEmojiLink().exists()).toBe(true);
      expect(findCreateNewEmojiLink().attributes('href')).toBe(mockCustomEmojiPath);
    });

    it('Injected newCustomEmojiPath is prioritized over customEmojiPath prop', async () => {
      createComponent({ newCustomEmojiPath: mockCustomEmojiPath, customEmojiPath: 'foo' });

      await showDropdown();

      expect(findCreateNewEmojiLink().exists()).toBe(true);
      expect(findCreateNewEmojiLink().attributes('href')).toBe(mockCustomEmojiPath);
    });
  });
});
