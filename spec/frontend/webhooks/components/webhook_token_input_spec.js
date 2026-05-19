import { GlAlert, GlFormGroup, GlSprintf } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import WebhookTokenInput from '~/webhooks/components/webhook_token_input.vue';
import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';

describe('WebhookTokenInput', () => {
  let wrapper;

  const DOCS_PATH = '/help/user/project/integrations/webhooks#signing-token';

  const createComponent = (props = {}) => {
    wrapper = shallowMountExtended(WebhookTokenInput, {
      propsData: {
        docsPath: DOCS_PATH,
        ...props,
      },
      stubs: { GlSprintf },
    });
  };

  const findRevealedBox = () => wrapper.findByTestId('signing-token-revealed');
  const findHiddenBox = () => wrapper.findByTestId('signing-token-hidden');
  const findTokenInput = () => wrapper.findByTestId('webhook-signing-token-input');
  const findToggleVisibilityButton = () => wrapper.findByTestId('toggle-visibility-button');
  const findClipboardButton = () => wrapper.findComponent(ClipboardButton);
  const findRegenerateButton = () => wrapper.findByTestId('regenerate-token-button');
  const findGenerateSigningTokenButton = () =>
    wrapper.findByTestId('generate-signing-token-button');
  const findFormGroup = () => wrapper.findComponent(GlFormGroup);
  const findAlert = () => wrapper.findComponent(GlAlert);

  describe('state: no_token (no existing token)', () => {
    beforeEach(() => {
      createComponent({ hasExistingToken: false });
    });

    it('renders the form group with signing token label', () => {
      expect(findFormGroup().exists()).toBe(true);
      expect(findFormGroup().attributes('label')).toBe('Signing token');
    });

    it('does not render a token input', () => {
      expect(findTokenInput().exists()).toBe(false);
    });

    it('renders a Generate signing token button', () => {
      expect(findGenerateSigningTokenButton().exists()).toBe(true);
    });

    it('does not render the revealed or hidden boxes', () => {
      expect(findRevealedBox().exists()).toBe(false);
      expect(findHiddenBox().exists()).toBe(false);
    });

    describe('when Generate signing token is clicked', () => {
      beforeEach(async () => {
        await findGenerateSigningTokenButton().vm.$emit('click');
      });

      it('transitions to token_revealed state', () => {
        expect(findGenerateSigningTokenButton().exists()).toBe(false);
        expect(findRevealedBox().exists()).toBe(true);
      });

      it('generates a whsec_ prefixed base64 token', () => {
        expect(findTokenInput().attributes('value')).toMatch(/^whsec_[A-Za-z0-9+/]{43}=$/);
      });

      it('shows the new-token warning (not the regeneration warning)', () => {
        expect(findAlert().text()).toContain('Save this token now');
        expect(findAlert().text()).not.toContain("apps that rely on the previous token won't work");
      });
    });
  });

  describe('state: token_hidden (edit mode, existing token)', () => {
    beforeEach(() => {
      createComponent({ hasExistingToken: true });
    });

    it('renders the form group with signing token label', () => {
      expect(findFormGroup().exists()).toBe(true);
    });

    it('renders the hidden token box', () => {
      expect(findHiddenBox().exists()).toBe(true);
    });

    it('does not render a submittable input (token is not overwritten)', () => {
      expect(findTokenInput().exists()).toBe(false);
    });

    it('does not render toggle visibility or clipboard buttons', () => {
      expect(findToggleVisibilityButton().exists()).toBe(false);
      expect(findClipboardButton().exists()).toBe(false);
    });

    it('renders only the regenerate button', () => {
      expect(findRegenerateButton().exists()).toBe(true);
    });

    describe('when Regenerate is clicked', () => {
      beforeEach(async () => {
        await findRegenerateButton().vm.$emit('click');
      });

      it('transitions to token_revealed state', () => {
        expect(findHiddenBox().exists()).toBe(false);
        expect(findRevealedBox().exists()).toBe(true);
      });

      it('generates a whsec_ prefixed base64 token', () => {
        expect(findTokenInput().attributes('value')).toMatch(/^whsec_[A-Za-z0-9+/]{43}=$/);
      });

      it('shows the regeneration warning mentioning previous token', () => {
        expect(findAlert().text()).toContain("apps that rely on the previous token won't work");
      });
    });
  });

  describe('state: token_revealed (regenerated from existing token)', () => {
    beforeEach(async () => {
      createComponent({ hasExistingToken: true });
      await findRegenerateButton().vm.$emit('click');
    });

    it('renders the alert with regeneration warning', () => {
      expect(findAlert().text()).toContain("apps that rely on the previous token won't work");
    });

    it('renders all action buttons', () => {
      expect(findToggleVisibilityButton().exists()).toBe(true);
      expect(findClipboardButton().exists()).toBe(true);
      expect(findRegenerateButton().exists()).toBe(true);
    });

    describe('when Regenerate is clicked again', () => {
      beforeEach(async () => {
        await findRegenerateButton().vm.$emit('click');
      });

      it('still shows the regeneration warning', () => {
        expect(findAlert().text()).toContain("apps that rely on the previous token won't work");
      });

      it('generates a new token', () => {
        expect(findTokenInput().attributes('value')).toMatch(/^whsec_[A-Za-z0-9+/]{43}=$/);
      });
    });
  });

  describe('docsPath prop', () => {
    it('passes docsPath to the description link in no_token state', () => {
      createComponent({ hasExistingToken: false, docsPath: DOCS_PATH });

      expect(findFormGroup().html()).toContain(DOCS_PATH);
    });

    it('passes docsPath to the description link in token_revealed state', async () => {
      createComponent({ hasExistingToken: false, docsPath: DOCS_PATH });
      await findGenerateSigningTokenButton().vm.$emit('click');

      expect(findFormGroup().html()).toContain(DOCS_PATH);
    });

    it('passes docsPath to the description link in token_hidden state', () => {
      createComponent({ hasExistingToken: true, docsPath: DOCS_PATH });

      expect(findFormGroup().html()).toContain(DOCS_PATH);
    });
  });
});
