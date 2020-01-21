import { shallowMount } from '@vue/test-utils';

import { eventHub } from '~/vue_shared/components/recaptcha_eventhub';

import RecaptchaModal from '~/vue_shared/components/recaptcha_modal';

describe('RecaptchaModal', () => {
  const recaptchaFormId = 'recaptcha-form';
  const recaptchaHtml = `<form id="${recaptchaFormId}"></form>`;

  let wrapper;

  const findRecaptchaForm = () => wrapper.find(`#${recaptchaFormId}`).element;

  beforeEach(() => {
    wrapper = shallowMount(RecaptchaModal, {
      propsData: {
        html: recaptchaHtml,
      },
    });
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('submits the form if event hub emits submit event', () => {
    const form = findRecaptchaForm();
    jest.spyOn(form, 'submit').mockImplementation();

    eventHub.$emit('submit');

    expect(form.submit).toHaveBeenCalled();
  });
});
