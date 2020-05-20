import createEventHub from '~/helpers/event_hub_factory';

// see recaptcha_tags in app/views/shared/_recaptcha_form.html.haml
export const callbackName = 'recaptchaDialogCallback';

export const eventHub = createEventHub();

const throwDuplicateCallbackError = () => {
  throw new Error(`${callbackName} is already defined!`);
};

if (window[callbackName]) {
  throwDuplicateCallbackError();
}

const callback = () => eventHub.$emit('submit');

Object.defineProperty(window, callbackName, {
  get: () => callback,
  set: throwDuplicateCallbackError,
});
