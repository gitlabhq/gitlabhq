import { shallowMount } from '@vue/test-utils';
import { GlSprintf, GlLink } from '@gitlab/ui';
import Component from '~/registry/explorer/components/list_page/registry_header.vue';
import TitleArea from '~/vue_shared/components/registry/title_area.vue';
import {
  CONTAINER_REGISTRY_TITLE,
  LIST_INTRO_TEXT,
  EXPIRATION_POLICY_DISABLED_MESSAGE,
  EXPIRATION_POLICY_DISABLED_TEXT,
  EXPIRATION_POLICY_WILL_RUN_IN,
} from '~/registry/explorer/constants';

jest.mock('~/lib/utils/datetime_utility', () => ({
  approximateDuration: jest.fn(),
  calculateRemainingMilliseconds: jest.fn(),
}));

describe('registry_header', () => {
  let wrapper;

  const findTitleArea = () => wrapper.find(TitleArea);
  const findCommandsSlot = () => wrapper.find('[data-testid="commands-slot"]');
  const findInfoArea = () => wrapper.find('[data-testid="info-area"]');
  const findIntroText = () => wrapper.find('[data-testid="default-intro"]');
  const findImagesCountSubHeader = () => wrapper.find('[data-testid="images-count"]');
  const findExpirationPolicySubHeader = () => wrapper.find('[data-testid="expiration-policy"]');
  const findDisabledExpirationPolicyMessage = () =>
    wrapper.find('[data-testid="expiration-disabled-message"]');

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

          expect(findImagesCountSubHeader().text()).toMatchInterpolatedText('1 Image repository');
        });

        it('when there is more than one image', async () => {
          await mountComponent({ imagesCount: 3 });

          expect(findImagesCountSubHeader().text()).toMatchInterpolatedText('3 Image repositories');
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
          expect(text.text()).toMatchInterpolatedText(EXPIRATION_POLICY_DISABLED_TEXT);
        });

        it('when is enabled', async () => {
          await mountComponent({
            expirationPolicy: { enabled: true },
            expirationPolicyHelpPagePath: 'foo',
            imagesCount: 1,
          });

          const text = findExpirationPolicySubHeader();
          expect(text.exists()).toBe(true);
          expect(text.text()).toMatchInterpolatedText(EXPIRATION_POLICY_WILL_RUN_IN);
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

  describe('info area', () => {
    it('exists', () => {
      mountComponent();

      expect(findInfoArea().exists()).toBe(true);
    });

    describe('default message', () => {
      beforeEach(() => {
        return mountComponent({ helpPagePath: 'bar' });
      });

      it('exists', () => {
        expect(findIntroText().exists()).toBe(true);
      });

      it('has the correct copy', () => {
        expect(findIntroText().text()).toMatchInterpolatedText(LIST_INTRO_TEXT);
      });

      it('has the correct link', () => {
        expect(
          findIntroText()
            .find(GlLink)
            .attributes('href'),
        ).toBe('bar');
      });
    });

    describe('expiration policy info message', () => {
      describe('when there are no images', () => {
        it('is hidden', () => {
          mountComponent();

          expect(findDisabledExpirationPolicyMessage().exists()).toBe(false);
        });
      });

      describe('when there are images', () => {
        describe('when expiration policy is disabled', () => {
          beforeEach(() => {
            return mountComponent({
              expirationPolicy: { enabled: false },
              expirationPolicyHelpPagePath: 'foo',
              imagesCount: 1,
            });
          });
          it('message exist', () => {
            expect(findDisabledExpirationPolicyMessage().exists()).toBe(true);
          });
          it('has the correct copy', () => {
            expect(findDisabledExpirationPolicyMessage().text()).toMatchInterpolatedText(
              EXPIRATION_POLICY_DISABLED_MESSAGE,
            );
          });

          it('has the correct link', () => {
            expect(
              findDisabledExpirationPolicyMessage()
                .find(GlLink)
                .attributes('href'),
            ).toBe('foo');
          });
        });

        describe('when expiration policy is enabled', () => {
          it('message does not exist', () => {
            mountComponent({
              expirationPolicy: { enabled: true },
              imagesCount: 1,
            });

            expect(findDisabledExpirationPolicyMessage().exists()).toBe(false);
          });
        });
        describe('when the expiration policy is completely disabled', () => {
          it('message does not exist', () => {
            mountComponent({
              expirationPolicy: { enabled: true },
              imagesCount: 1,
              hideExpirationPolicyData: true,
            });

            expect(findDisabledExpirationPolicyMessage().exists()).toBe(false);
          });
        });
      });
    });
  });
});
