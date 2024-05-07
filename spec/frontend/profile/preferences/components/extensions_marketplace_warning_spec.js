import { nextTick } from 'vue';
import { GlModal, GlSprintf } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import ExtensionsMarketplaceWarning, {
  WARNING_PARAGRAPH_1,
  WARNING_PARAGRAPH_2,
  WARNING_PARAGRAPH_3,
} from '~/profile/preferences/components/extensions_marketplace_warning.vue';

const TEST_HELP_URL = 'http://localhost/help/url';
const TEST_MARKETPLACE_URL = 'http://localhost/extensions/marketplace';

describe('profile/preferences/components/extensions_marketplace_warning', () => {
  let wrapper;

  const createComponent = (props = {}) => {
    wrapper = shallowMount(ExtensionsMarketplaceWarning, {
      propsData: {
        value: false,
        helpUrl: TEST_HELP_URL,
        ...props,
      },
      provide: {
        extensionsMarketplaceUrl: TEST_MARKETPLACE_URL,
      },
      stubs: {
        GlSprintf,
      },
    });
  };

  const findModal = () => wrapper.findComponent(GlModal);

  const closeModal = async () => {
    findModal().vm.$emit('change', false);
    findModal().vm.$emit('hide');

    await nextTick();
  };

  const setValue = async (value) => {
    wrapper.setProps({ value });
    await nextTick();
  };

  describe('when initializes with value: false', () => {
    beforeEach(() => {
      createComponent({ value: false });
    });

    it('does not show modal', () => {
      expect(findModal().props('visible')).toBe(false);
    });

    describe('when value changes to true', () => {
      beforeEach(async () => {
        await setValue(true);
      });

      it('shows modal with props', () => {
        expect(findModal().props()).toMatchObject({
          visible: true,
          modalId: 'extensions-marketplace-warning-modal',
          title: 'Third-Party Extensions Acknowledgement',
          actionPrimary: {
            text: 'I understand',
          },
          actionSecondary: {
            text: 'Learn more',
            attributes: {
              href: TEST_HELP_URL,
              variant: 'default',
            },
          },
        });
      });

      it('shows modal text', () => {
        expect(findModal().text()).toMatchInterpolatedText(
          `${WARNING_PARAGRAPH_1} ${WARNING_PARAGRAPH_2} ${WARNING_PARAGRAPH_3}`.replace(
            '%{url}',
            TEST_MARKETPLACE_URL,
          ),
        );
      });

      it('emits input to reset value to false', () => {
        expect(wrapper.emitted('input')).toEqual([[false]]);
      });

      describe('when modal canceled', () => {
        beforeEach(async () => {
          await closeModal();
        });

        it('does not change anything', () => {
          expect(wrapper.emitted('input')).toEqual([[false]]);
        });

        it('opens modal again when value changes', async () => {
          await setValue(false);

          expect(findModal().props('visible')).toBe(false);

          await setValue(true);

          expect(findModal().props('visible')).toBe(true);
        });
      });

      describe('when modal is accepted', () => {
        beforeEach(async () => {
          findModal().vm.$emit('primary');

          await closeModal();
        });

        it('updates value', () => {
          expect(wrapper.emitted('input')).toEqual([[false], [true]]);
        });

        it('does not open modal when value changes', async () => {
          await setValue(false);

          expect(findModal().props('visible')).toBe(false);

          await setValue(true);

          expect(findModal().props('visible')).toBe(false);
        });
      });
    });
  });

  describe('when initiailized with value: true', () => {
    beforeEach(() => {
      createComponent({ value: true });
    });

    it('does not show modal', () => {
      expect(findModal().props('visible')).toBe(false);
    });

    it('does not open modal when value changes', async () => {
      await setValue(false);

      expect(findModal().props('visible')).toBe(false);

      await setValue(true);

      expect(findModal().props('visible')).toBe(false);
    });
  });
});
