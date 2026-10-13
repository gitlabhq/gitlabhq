import { GlLink } from '@gitlab/ui';
import waitForPromises from 'helpers/wait_for_promises';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import { iframeProviders } from 'helpers/iframe_providers';
import ExternalContent from '~/behaviors/components/external_content.vue';

describe('ExternalContent', () => {
  let wrapper;

  const createComponent = ({ provider = iframeProviders().figma, listeners, ...props } = {}) => {
    wrapper = mountExtended(ExternalContent, {
      propsData: {
        provider,
        href: 'https://www.figma.com/design/abc/Thing',
        ...props,
      },
      listeners,
      scopedSlots: {
        default({ title }) {
          return this.$createElement('iframe', {
            attrs: { 'data-testid': 'embedded-content', title },
          });
        },
      },
    });
  };

  const findContent = () => wrapper.findByTestId('embedded-content');
  const findPlaceholder = () => wrapper.findByTestId('external-content-placeholder');
  const findHeading = () => wrapper.findByTestId('external-content-heading');
  const findActivationButton = () =>
    wrapper.findByRole('button', { name: 'Load external content' });
  const findWarning = () => wrapper.findByTestId('external-content-warning');
  const findOpenInNewTab = () => wrapper.findByTestId('external-content-open-in-new-tab');

  describe('when the provider requires activation', () => {
    let onActivated;

    beforeEach(() => {
      onActivated = jest.fn(() => findContent().exists());
      createComponent({ listeners: { activated: onActivated } });
    });

    it('does not render the content', () => {
      expect(findContent().exists()).toBe(false);
    });

    it('does not render the warning', () => {
      expect(findWarning().exists()).toBe(false);
    });

    it('identifies the provider and host', () => {
      expect(findHeading().text()).toBe('External content from Figma (embed.figma.com)');
    });

    it('explains what loading the content does', () => {
      expect(findPlaceholder().text()).toContain(
        'If you load this content, embed.figma.com receives your IP address and browser information.',
      );
    });

    it('describes the activation button with the heading and explanation', () => {
      const describedBy = findActivationButton().attributes('aria-describedby').split(' ');

      expect(describedBy).toHaveLength(2);
      expect(describedBy[0]).toBe(findHeading().attributes('id'));
      expect(wrapper.find(`[id="${describedBy[1]}"]`).text()).toContain(
        'GitLab cannot verify how embed.figma.com uses this data.',
      );
    });

    describe('when the user activates the content', () => {
      beforeEach(async () => {
        findActivationButton().trigger('click');
        await waitForPromises();
      });

      it('renders the content', () => {
        expect(findContent().exists()).toBe(true);
      });

      it('emits activated once the content has rendered', () => {
        expect(onActivated.mock.results).toEqual([{ type: 'return', value: true }]);
      });

      it('removes the placeholder', () => {
        expect(findPlaceholder().exists()).toBe(false);
      });

      it('renders the warning', () => {
        expect(findWarning().text()).toContain(
          'You are viewing external content from embed.figma.com. GitLab does not control this content.',
        );
      });
    });
  });

  describe('when the provider does not require activation', () => {
    beforeEach(() => {
      createComponent({ provider: iframeProviders().youtube, href: 'https://youtu.be/abc' });
    });

    it('renders the content', () => {
      expect(findContent().exists()).toBe(true);
    });

    it('does not render the placeholder', () => {
      expect(findPlaceholder().exists()).toBe(false);
    });

    it('renders the warning', () => {
      expect(findWarning().text()).toContain(
        'You are viewing external content from www.youtube.com. GitLab does not control this content.',
      );
    });

    it('does not announce the warning as an alert', () => {
      expect(findWarning().attributes()).toMatchObject({ role: 'note', 'aria-live': 'off' });
    });

    it('links to the content in a new tab', () => {
      expect(findOpenInNewTab().attributes()).toMatchObject({
        href: 'https://youtu.be/abc',
        target: '_blank',
        rel: 'noopener noreferrer',
      });
    });

    it('marks the link as external', () => {
      expect(findOpenInNewTab().findComponent(GlLink).props('showExternalIcon')).toBe(true);
    });

    it('names the content after the provider and host', () => {
      expect(findContent().attributes('title')).toBe(
        'External content from YouTube (www.youtube.com)',
      );
    });
  });

  describe('when there is no link to the content', () => {
    beforeEach(() => {
      createComponent({ provider: iframeProviders().youtube, href: null });
    });

    it('renders the warning', () => {
      expect(findWarning().exists()).toBe(true);
    });

    it('does not link to the content', () => {
      expect(findOpenInNewTab().exists()).toBe(false);
    });
  });

  describe('when the provider name contains HTML special characters', () => {
    beforeEach(() => {
      createComponent({ provider: { ...iframeProviders().youtube, name: 'Tom & Jerry' } });
    });

    it('names the content without escaping', () => {
      expect(findContent().attributes('title')).toBe(
        'External content from Tom & Jerry (www.youtube.com)',
      );
    });
  });

  describe('layout', () => {
    it('keeps the content within its container, with a floor that yields to it', () => {
      createComponent();

      expect(wrapper.element.style.maxWidth).toBe('100%');
      expect(wrapper.element.style.minWidth).toBe('min(17rem, 100%)');
    });

    describe('when the provider requires activation', () => {
      beforeEach(() => {
        createComponent({ width: '10' });
      });

      it('fills the floor with the placeholder', () => {
        expect(findPlaceholder().classes()).toContain('gl-min-w-full');
      });
    });

    describe('when the provider does not require activation', () => {
      beforeEach(() => {
        createComponent({ provider: iframeProviders().youtube });
      });

      it('wraps the warning anywhere rather than overflowing', () => {
        expect(findWarning().classes()).toContain('gl-wrap-anywhere');
      });
    });
  });

  describe('placeholder dimensions', () => {
    describe('when the content has explicit dimensions', () => {
      beforeEach(() => {
        createComponent({ width: '560', height: '315' });
      });

      it('is as wide as the content, within its container', () => {
        expect(findPlaceholder().element.style.width).toBe('560px');
        expect(findPlaceholder().element.style.maxWidth).toBe('100%');
      });

      it('takes its height from the aspect ratio rather than a fixed minimum', () => {
        expect(findPlaceholder().element.style.minHeight).toBe('');
      });
    });

    describe('when the content has dimensions with units', () => {
      beforeEach(() => {
        createComponent({ width: '50%', height: '200px' });
      });

      it('keeps the units', () => {
        expect(findPlaceholder().element.style.width).toBe('50%');
        expect(findPlaceholder().element.style.minHeight).toBe('200px');
      });
    });

    describe('when the content has no explicit dimensions', () => {
      beforeEach(() => {
        createComponent();
      });

      it('sizes to its own content', () => {
        expect(findPlaceholder().element.style.width).toBe('');
        expect(findPlaceholder().element.style.minHeight).toBe('');
      });
    });
  });
});
