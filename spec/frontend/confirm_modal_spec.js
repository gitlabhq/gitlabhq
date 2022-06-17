import { TEST_HOST } from 'helpers/test_constants';
import initConfirmModal from '~/confirm_modal';

describe('ConfirmModal', () => {
  const buttons = [
    {
      path: `${TEST_HOST}/1`,
      method: 'delete',
      modalAttributes: {
        title: 'Remove tracking database entry',
        message: 'Tracking database entry will be removed. Are you sure?',
        okVariant: 'danger',
        okTitle: 'Remove entry',
      },
    },
    {
      path: `${TEST_HOST}/1`,
      method: 'post',
      modalAttributes: {
        title: 'Update tracking database entry',
        message: 'Tracking database entry will be updated. Are you sure?',
        okVariant: 'success',
        okTitle: 'Update entry',
      },
    },
  ];

  beforeEach(() => {
    const buttonContainer = document.createElement('div');

    buttons.forEach((x) => {
      const button = document.createElement('button');
      button.setAttribute('class', 'js-confirm-modal-button');
      button.dataset.path = x.path;
      button.dataset.method = x.method;
      button.dataset.modalAttributes = JSON.stringify(x.modalAttributes);
      button.innerHTML = 'Action';
      buttonContainer.appendChild(button);
    });

    document.body.appendChild(buttonContainer);
  });

  afterEach(() => {
    document.body.innerHTML = '';
  });

  const findJsHooks = () => document.querySelectorAll('.js-confirm-modal-button');
  const findModal = () => document.querySelector('.gl-modal');
  const findModalOkButton = (modal, variant) =>
    modal.querySelector(`.modal-footer .btn-${variant}`);
  const modalIsHidden = () => findModal() === null;

  const serializeModal = (modal, buttonIndex) => {
    const { modalAttributes } = buttons[buttonIndex];

    return {
      path: modal.querySelector('form').action,
      method: modal.querySelector('input[name="_method"]').value,
      modalAttributes: {
        title: modal.querySelector('.modal-title').innerHTML,
        message: modal.querySelector('.modal-body div').innerHTML,
        okVariant: [...findModalOkButton(modal, modalAttributes.okVariant).classList]
          .find((x) => x.match('btn-'))
          .replace('btn-', ''),
        okTitle: findModalOkButton(modal, modalAttributes.okVariant).innerHTML,
      },
    };
  };

  it('starts with only JsHooks', () => {
    expect(findJsHooks()).toHaveLength(buttons.length);
    expect(findModal()).toBe(null);
  });

  describe('when button clicked', () => {
    beforeEach(() => {
      initConfirmModal();
      findJsHooks().item(0).click();
    });

    it('does not replace JsHook with GlModal', () => {
      expect(findJsHooks()).toHaveLength(buttons.length);
    });

    describe('GlModal', () => {
      it('is rendered', () => {
        expect(findModal()).not.toBe(null);
        expect(modalIsHidden()).toBe(false);
      });
    });
  });

  describe.each`
    index
    ${0}
    ${1}
  `(`when multiple buttons exist`, ({ index }) => {
    beforeEach(() => {
      initConfirmModal();
      findJsHooks().item(index).click();
    });

    it('correct props are passed to gl-modal', () => {
      expect(serializeModal(findModal(), index)).toEqual(buttons[index]);
    });
  });
});
