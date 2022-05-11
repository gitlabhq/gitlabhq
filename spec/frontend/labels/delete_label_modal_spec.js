import { TEST_HOST } from 'helpers/test_constants';
import { initDeleteLabelModal } from '~/labels';

describe('DeleteLabelModal', () => {
  const buttons = [
    {
      labelName: 'label 1',
      subjectName: 'GitLab Org',
      destroyPath: `${TEST_HOST}/1`,
    },
    {
      labelName: 'label 2',
      subjectName: 'GitLab Org',
      destroyPath: `${TEST_HOST}/2`,
    },
    {
      labelName: 'admin label',
      destroyPath: `${TEST_HOST}/3`,
    },
  ];

  beforeEach(() => {
    const buttonContainer = document.createElement('div');

    buttons.forEach((x) => {
      const button = document.createElement('button');
      button.setAttribute('class', 'js-delete-label-modal-button');
      button.dataset.labelName = x.labelName;
      button.dataset.destroyPath = x.destroyPath;

      if (x.subjectName) {
        button.dataset.subjectName = x.subjectName;
      }

      button.innerHTML = 'Action';
      buttonContainer.appendChild(button);
    });

    document.body.appendChild(buttonContainer);
  });

  afterEach(() => {
    document.body.innerHTML = '';
  });

  const findJsHooks = () => document.querySelectorAll('.js-delete-label-modal-button');
  const findModal = () => document.querySelector('.gl-modal');

  it('starts with only js-containers', () => {
    expect(findJsHooks()).toHaveLength(buttons.length);
    expect(findModal()).toBe(null);
  });

  describe('when first button clicked', () => {
    beforeEach(() => {
      initDeleteLabelModal();
      findJsHooks().item(0).click();
    });

    it('does not replace js-containers with GlModal', () => {
      expect(findJsHooks()).toHaveLength(buttons.length);
    });

    it('renders GlModal', () => {
      expect(findModal()).not.toBe(null);
    });
  });

  describe.each`
    index
    ${0}
    ${1}
    ${2}
  `(`when multiple buttons exist`, ({ index }) => {
    beforeEach(() => {
      initDeleteLabelModal();
      findJsHooks().item(index).click();
    });

    it('correct props are passed to gl-modal', () => {
      const button = buttons[index];

      expect(findModal().querySelector('.modal-title').innerHTML).toContain(button.labelName);

      if (button.subjectName) {
        expect(findModal().querySelector('.modal-body').textContent).toContain(
          `${button.labelName} will be permanently deleted from ${button.subjectName}. This cannot be undone.`,
        );
      } else {
        expect(findModal().querySelector('.modal-body').textContent).toContain(
          `${button.labelName} will be permanently deleted. This cannot be undone.`,
        );
      }

      expect(findModal().querySelector('.modal-footer .btn-danger').href).toContain(
        button.destroyPath,
      );
    });
  });
});
