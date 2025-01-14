import { GlAlert } from '@gitlab/ui';
import { nextTick } from 'vue';
import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import NewAccessTokenApp from '~/access_tokens/components/new_access_token_app.vue';
import { EVENT_ERROR, EVENT_SUCCESS, FORM_SELECTOR } from '~/access_tokens/components/constants';
import { createAlert, VARIANT_INFO } from '~/alert';
import { sprintf } from '~/locale';
import DomElementListener from '~/vue_shared/components/dom_element_listener.vue';
import InputCopyToggleVisibility from '~/vue_shared/components/input_copy_toggle_visibility/input_copy_toggle_visibility.vue';

jest.mock('~/alert');

describe('~/access_tokens/components/new_access_token_app', () => {
  let wrapper;

  const accessTokenType = 'personal access token';

  const createComponent = (provide = { accessTokenType }) => {
    wrapper = shallowMountExtended(NewAccessTokenApp, {
      provide,
    });
  };

  const findButtonEl = () => document.querySelector('[type=submit]');
  const findGlAlertError = () => wrapper.findByTestId('error-message');
  const findGlAlertSuccess = () => wrapper.findByTestId('success-message');

  const triggerSuccess = async (newToken = 'new token') => {
    wrapper
      .findComponent(DomElementListener)
      .vm.$emit(EVENT_SUCCESS, { detail: [{ new_token: newToken }] });
    await nextTick();
  };

  const triggerError = async (errors = ['1', '2']) => {
    wrapper.findComponent(DomElementListener).vm.$emit(EVENT_ERROR, { detail: [{ errors }] });
    await nextTick();
  };

  beforeEach(() => {
    // NewAccessTokenApp observes a form element
    setHTMLFixture(
      `<form id="${FORM_SELECTOR.slice(1)}">
        <input type="text" id="expires_at" value="2022-01-01"/>
        <input type="text" value='1'/>
        <input type="checkbox" checked/>
        <textarea>my description</textarea>
        <button type="submit" data-testid="create-token-button" value="Create" class="disabled" disabled="disabled"/>
      </form>`,
    );

    createComponent();
  });

  afterEach(() => {
    resetHTMLFixture();
    createAlert.mockClear();
  });

  it('should render nothing', () => {
    expect(wrapper.findComponent(InputCopyToggleVisibility).exists()).toBe(false);
    expect(findGlAlertError().exists()).toBe(false);
  });

  describe('on success', () => {
    it('should render `InputCopyToggleVisibility` component', async () => {
      const newToken = '12345';
      await triggerSuccess(newToken);

      expect(findGlAlertError().exists()).toBe(false);
      expect(findGlAlertSuccess().exists()).toBe(true);

      const InputCopyToggleVisibilityComponent = wrapper.findComponent(InputCopyToggleVisibility);
      expect(InputCopyToggleVisibilityComponent.props('value')).toBe(newToken);
      expect(InputCopyToggleVisibilityComponent.props('readonly')).toBe(true);
      expect(InputCopyToggleVisibilityComponent.props('copyButtonTitle')).toBe(
        sprintf('Copy %{accessTokenType}', { accessTokenType }),
      );
      expect(InputCopyToggleVisibilityComponent.attributes('label')).toBe(
        sprintf('Your new %{accessTokenType}', { accessTokenType }),
      );
    });

    it('should render an info alert', async () => {
      await triggerSuccess();

      expect(createAlert).toHaveBeenCalledWith({
        message: sprintf('Your new %{accessTokenType} has been created.', {
          accessTokenType,
        }),
        variant: VARIANT_INFO,
      });
    });

    it('should enable the submit button', async () => {
      const button = findButtonEl();
      expect(button).toBeDisabled();
      expect(button.className).toBe('disabled');

      await triggerSuccess();

      expect(button).not.toBeDisabled();
      expect(button.className).toBe('');
    });

    describe('when resetting the form', () => {
      it('should reset selectively some input fields', async () => {
        expect(document.querySelector('input[type=text]:not([id$=expires_at])').value).toBe('1');
        expect(document.querySelector('input[type=checkbox]').checked).toBe(true);
        expect(document.querySelector('textarea').value).toBe('my description');
        await triggerSuccess();

        expect(document.querySelector('input[type=text]:not([id$=expires_at])').value).toBe('');
        expect(document.querySelector('input[type=checkbox]').checked).toBe(false);
        expect(document.querySelector('textarea').value).toBe('');
      });

      it('should not reset the date field', async () => {
        expect(document.querySelector('input[type=text][id$=expires_at]').value).toBe('2022-01-01');
        await triggerSuccess();

        expect(document.querySelector('input[type=text][id$=expires_at]').value).toBe('2022-01-01');
      });

      it('should not reset the submit button value', async () => {
        expect(findButtonEl().value).toBe('Create');
        await triggerSuccess();

        expect(findButtonEl().value).toBe('Create');
      });
    });
  });

  describe('on error', () => {
    it('should render an error alert', async () => {
      await triggerError(['first', 'second']);

      expect(wrapper.findComponent(InputCopyToggleVisibility).exists()).toBe(false);

      let GlAlertComponent = findGlAlertError();
      expect(GlAlertComponent.props('title')).toBe('The form contains the following errors:');
      expect(GlAlertComponent.props('variant')).toBe('danger');
      let itemEls = wrapper.findAll('li');
      expect(itemEls).toHaveLength(2);
      expect(itemEls.at(0).text()).toBe('first');
      expect(itemEls.at(1).text()).toBe('second');

      await triggerError(['one']);

      GlAlertComponent = wrapper.findComponent(GlAlert);
      expect(GlAlertComponent.props('title')).toBe('The form contains the following error:');
      expect(GlAlertComponent.props('variant')).toBe('danger');
      itemEls = wrapper.findAll('li');
      expect(itemEls).toHaveLength(1);
    });

    it('the error alert should be dismissible', async () => {
      await triggerError();

      const GlAlertComponent = wrapper.findComponent(GlAlert);
      expect(GlAlertComponent.exists()).toBe(true);

      GlAlertComponent.vm.$emit('dismiss');
      await nextTick();

      expect(wrapper.findComponent(GlAlert).exists()).toBe(false);
    });

    it('should enable the submit button', async () => {
      const button = findButtonEl();
      expect(button).toBeDisabled();
      expect(button.className).toBe('disabled');

      await triggerError();

      expect(button).not.toBeDisabled();
      expect(button.className).toBe('');
    });
  });

  describe('before error or success', () => {
    it('should scroll to the container', async () => {
      const containerEl = wrapper.vm.$refs.container;
      const scrollIntoViewSpy = jest.spyOn(containerEl, 'scrollIntoView');

      await triggerSuccess();

      expect(scrollIntoViewSpy).toHaveBeenCalledWith(false);
      expect(scrollIntoViewSpy).toHaveBeenCalledTimes(1);

      await triggerError();

      expect(scrollIntoViewSpy).toHaveBeenCalledWith(false);
      expect(scrollIntoViewSpy).toHaveBeenCalledTimes(2);
    });

    it('should dismiss the info alert', async () => {
      const dismissSpy = jest.fn();
      createAlert.mockReturnValue({ dismiss: dismissSpy });

      await triggerSuccess();
      await triggerError();

      expect(dismissSpy).toHaveBeenCalled();
      expect(dismissSpy).toHaveBeenCalledTimes(1);
    });
  });
});
