import { TEST_HOST } from 'helpers/test_constants';
import initDeleteLabelModal from '~/delete_label_modal';

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
  ];

  beforeEach(() => {
    const buttonContainer = document.createElement('div');

    buttons.forEach((x) => {
      const button = document.createElement('button');
      button.setAttribute('class', 'js-delete-label-modal-button');
      button.setAttribute('data-label-name', x.labelName);
      button.setAttribute('data-subject-name', x.subjectName);
      button.setAttribute('data-destroy-path', x.destroyPath);
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
    expect(findModal()).not.toExist();
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
      expect(findModal()).toExist();
    });
  });

  describe.each`
    index
    ${0}
    ${1}
  `(`when multiple buttons exist`, ({ index }) => {
    beforeEach(() => {
      initDeleteLabelModal();
      findJsHooks().item(index).click();
    });

    it('correct props are passed to gl-modal', () => {
      expect(findModal().querySelector('.modal-title').innerHTML).toContain(
        buttons[index].labelName,
      );
      expect(findModal().querySelector('.modal-body').innerHTML).toContain(
        buttons[index].subjectName,
      );
      expect(findModal().querySelector('.modal-footer .btn-danger').href).toContain(
        buttons[index].destroyPath,
      );
    });
  });
});
