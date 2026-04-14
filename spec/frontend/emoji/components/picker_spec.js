import { nextTick } from 'vue';
import { shallowMount } from '@vue/test-utils';
import { GlButton, GlSearchBoxByType, GlDisclosureDropdown } from '@gitlab/ui';
import { stubComponent } from 'helpers/stub_component';
import waitForPromises from 'helpers/wait_for_promises';
import VirtualList from '~/emoji/components/virtual_list.vue';
import EmojiPicker from '~/emoji/components/picker.vue';
import * as utils from '~/emoji/components/utils';
import { CATEGORY_NAMES, FREQUENTLY_USED_KEY } from '~/emoji/constants';

describe('Emoji Picker component', () => {
  let wrapper;

  const createComponent = (
    { newCustomEmojiPath = '', customEmojiPath = '', ...rest } = {},
    stubs = {},
  ) => {
    wrapper = shallowMount(EmojiPicker, {
      stubs: {
        GlDisclosureDropdown,
        EmojiList: {
          template: '<div><slot :filtered-categories="{}"></slot></div>',
        },
        ...stubs,
      },
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
  const findCategoryButtonComponents = () =>
    wrapper.find('[data-testid="category-buttons"]').findAllComponents(GlButton);
  const findVirtualList = () => wrapper.findComponent(VirtualList);
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

  describe('toggleAriaLabel prop', () => {
    it('passes toggleAriaLabel to GlDisclosureDropdown', () => {
      createComponent({ toggleAriaLabel: 'Add reaction to @root' });

      expect(findDropdown().props('toggleAriaLabel')).toBe('Add reaction to @root');
    });

    it('defaults toggleAriaLabel to null', () => {
      createComponent();

      expect(findDropdown().props('toggleAriaLabel')).toBeNull();
    });
  });

  describe('when dropdown is hidden', () => {
    beforeEach(() => {
      createComponent();
    });

    it('does not render search box or category buttons', () => {
      expect(findSearchBox().exists()).toBe(false);
      expect(findCategoryButtons().exists()).toBe(false);
    });
  });

  describe('when dropdown is shown', () => {
    beforeEach(async () => {
      createComponent();
      await showDropdown();
    });

    it('renders search box and category buttons', () => {
      expect(findSearchBox().exists()).toBe(true);
      expect(findCategoryButtons().exists()).toBe(true);
    });

    describe('and then hidden', () => {
      beforeEach(async () => {
        await findDropdown().vm.$emit('hidden');
        await nextTick();
      });

      it('hides search box and category buttons', () => {
        expect(findSearchBox().exists()).toBe(false);
        expect(findCategoryButtons().exists()).toBe(false);
      });
    });
  });

  describe('onScroll category highlight', () => {
    const mockCategories = (includeFreqUsed) => {
      let top = 0;
      const entries = {};

      CATEGORY_NAMES.filter(
        (c) => c !== 'custom' && (includeFreqUsed || c !== FREQUENTLY_USED_KEY),
      ).forEach((name) => {
        const height = name === FREQUENTLY_USED_KEY ? 73 : 200;
        entries[name] = { emojis: [], height, top };
        top += height;
      });

      return entries;
    };

    describe.each([true, false])('when frequently_used is %s', (hasFreqUsed) => {
      const categories = mockCategories(hasFreqUsed);

      beforeEach(async () => {
        jest.spyOn(utils, 'getEmojiCategories').mockResolvedValue(categories);
        jest.spyOn(utils, 'hasFrequentlyUsedEmojis').mockReturnValue(hasFreqUsed);

        createComponent();
        await showDropdown();
      });

      const emitScroll = async (offset) => {
        findVirtualList().vm.$emit('scroll', { offset });
        await waitForPromises();
      };

      it('highlights the first tab at offset 0', async () => {
        await emitScroll(0);

        const buttons = findCategoryButtonComponents();
        expect(buttons.at(0).classes()).toContain('emoji-picker-category-active');
        expect(buttons.at(0).attributes('aria-label')).toBe(
          hasFreqUsed ? 'frequently_used' : 'Smileys & Emotion',
        );
      });

      it('highlights the second tab when scrolled past the first category', async () => {
        const firstCategoryHeight = hasFreqUsed ? 73 : 200;
        await emitScroll(firstCategoryHeight);

        const buttons = findCategoryButtonComponents();
        expect(buttons.at(0).classes()).not.toContain('emoji-picker-category-active');
        expect(buttons.at(1).classes()).toContain('emoji-picker-category-active');
        expect(buttons.at(1).attributes('aria-label')).toBe(
          hasFreqUsed ? 'Smileys & Emotion' : 'People & Body',
        );
      });

      it('highlights Flags (last tab) when scrolled to the end', async () => {
        const lastCategory = categories.Flags;
        await emitScroll(lastCategory.top + 10);

        const buttons = findCategoryButtonComponents();
        const lastButton = buttons.at(buttons.length - 1);
        expect(lastButton.classes()).toContain('emoji-picker-category-active');
        expect(lastButton.attributes('aria-label')).toBe('Flags');
      });

      it('highlights the correct tab for a mid-range offset', async () => {
        const { top } = categories.Objects;
        await emitScroll(top + 50);

        const buttons = findCategoryButtonComponents();
        const activeButtons = buttons.wrappers.filter((b) =>
          b.classes().includes('emoji-picker-category-active'),
        );
        expect(activeButtons).toHaveLength(1);
        expect(activeButtons[0].attributes('aria-label')).toBe('Objects');
      });
    });
  });

  describe('create new emoji link', () => {
    const mockCustomEmojiPath = '/groups/gitlab-org/-/custom_emoji/new';

    describe('when newCustomEmojiPath is provided', () => {
      it('shows the emoji with custom link', async () => {
        createComponent({ newCustomEmojiPath: mockCustomEmojiPath });

        await showDropdown();

        expect(findCreateNewEmojiLink().exists()).toBe(true);
        expect(findCreateNewEmojiLink().attributes('href')).toBe(mockCustomEmojiPath);
      });
    });

    it('when customEmojiPath prop is present', async () => {
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
