import { shallowMount } from '@vue/test-utils';
import { GlSprintf } from '@gitlab/ui';
import Component from '~/registry/explorer/components/list_page/registry_header.vue';
import TitleArea from '~/vue_shared/components/registry/title_area.vue';
import {
  CONTAINER_REGISTRY_TITLE,
  LIST_INTRO_TEXT,
  EXPIRATION_POLICY_DISABLED_MESSAGE,
  EXPIRATION_POLICY_DISABLED_TEXT,
} from '~/registry/explorer/constants';

jest.mock('~/lib/utils/datetime_utility', () => ({
  approximateDuration: jest.fn(),
  calculateRemainingMilliseconds: jest.fn(),
}));

describe('registry_header', () => {
  let wrapper;

  const findTitleArea = () => wrapper.find(TitleArea);
  const findCommandsSlot = () => wrapper.find('[data-testid="commands-slot"]');
  const findImagesCountSubHeader = () => wrapper.find('[data-testid="images-count"]');
  const findExpirationPolicySubHeader = () => wrapper.find('[data-testid="expiration-policy"]');

  const mountComponent = (propsData, slots) => {
    wrapper = shallowMount(Component, {
      stubs: {
        GlSprintf,
        TitleArea,
      },
      propsData,
      slots,
    });
    return wrapper.vm.$nextTick();
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('header', () => {
    it('has a title', () => {
      mountComponent();

      expect(findTitleArea().props('title')).toBe(CONTAINER_REGISTRY_TITLE);
    });

    it('has a commands slot', () => {
      mountComponent(null, { commands: '<div data-testid="commands-slot">baz</div>' });

      expect(findCommandsSlot().text()).toBe('baz');
    });

    describe('sub header parts', () => {
      describe('images count', () => {
        it('exists', async () => {
          await mountComponent({ imagesCount: 1 });

          expect(findImagesCountSubHeader().exists()).toBe(true);
        });

        it('when there is one image', async () => {
          await mountComponent({ imagesCount: 1 });

          expect(findImagesCountSubHeader().props()).toMatchObject({
            text: '1 Image repository',
            icon: 'container-image',
          });
        });

        it('when there is more than one image', async () => {
          await mountComponent({ imagesCount: 3 });

          expect(findImagesCountSubHeader().props('text')).toBe('3 Image repositories');
        });
      });

      describe('expiration policy', () => {
        it('when is disabled', async () => {
          await mountComponent({
            expirationPolicy: { enabled: false },
            expirationPolicyHelpPagePath: 'foo',
            imagesCount: 1,
          });

          const text = findExpirationPolicySubHeader();
          expect(text.exists()).toBe(true);
          expect(text.props()).toMatchObject({
            text: EXPIRATION_POLICY_DISABLED_TEXT,
            icon: 'expire',
            size: 'xl',
          });
        });

        it('when is enabled', async () => {
          await mountComponent({
            expirationPolicy: { enabled: true },
            expirationPolicyHelpPagePath: 'foo',
            imagesCount: 1,
          });

          const text = findExpirationPolicySubHeader();
          expect(text.exists()).toBe(true);
          expect(text.props('text')).toBe('Expiration policy will run in ');
        });
        it('when the expiration policy is completely disabled', async () => {
          await mountComponent({
            expirationPolicy: { enabled: true },
            expirationPolicyHelpPagePath: 'foo',
            imagesCount: 1,
            hideExpirationPolicyData: true,
          });

          const text = findExpirationPolicySubHeader();
          expect(text.exists()).toBe(false);
        });
      });
    });
  });

  describe('info messages', () => {
    describe('default message', () => {
      it('is correctly bound to title_area props', () => {
        mountComponent({ helpPagePath: 'foo' });

        expect(findTitleArea().props('infoMessages')).toEqual([
          { text: LIST_INTRO_TEXT, link: 'foo' },
        ]);
      });
    });

    describe('expiration policy info message', () => {
      describe('when there are images', () => {
        describe('when expiration policy is disabled', () => {
          beforeEach(() => {
            return mountComponent({
              expirationPolicy: { enabled: false },
              expirationPolicyHelpPagePath: 'foo',
              imagesCount: 1,
            });
          });

          it('the prop is correctly bound', () => {
            expect(findTitleArea().props('infoMessages')).toEqual([
              { text: LIST_INTRO_TEXT, link: '' },
              { text: EXPIRATION_POLICY_DISABLED_MESSAGE, link: 'foo' },
            ]);
          });
        });

        describe.each`
          desc                                                   | props
          ${'when there are no images'}                          | ${{ expirationPolicy: { enabled: false }, imagesCount: 0 }}
          ${'when expiration policy is enabled'}                 | ${{ expirationPolicy: { enabled: true }, imagesCount: 1 }}
          ${'when the expiration policy is completely disabled'} | ${{ expirationPolicy: { enabled: false }, imagesCount: 1, hideExpirationPolicyData: true }}
        `('$desc', ({ props }) => {
          it('message does not exist', () => {
            mountComponent(props);

            expect(findTitleArea().props('infoMessages')).toEqual([
              { text: LIST_INTRO_TEXT, link: '' },
            ]);
          });
        });
      });
    });
  });
});
