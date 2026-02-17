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
