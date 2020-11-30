import { TEST_HOST } from 'helpers/test_constants';
import { findAllByText, fireEvent, getByLabelText, screen } from '@testing-library/dom';
import { initIde } from '~/ide';
import extendStore from '~/ide/stores/extend';
import { IDE_DATASET } from './mock_data';

const isFolderRowOpen = row => row.matches('.folder.is-open');

const getLeftSidebar = () => screen.getByTestId('left-sidebar');

const clickOnLeftSidebarTab = name => {
  const sidebar = getLeftSidebar();

  const button = getByLabelText(sidebar, name);

  button.click();
};

export const findMonacoEditor = () =>
  screen.findByLabelText(/Editor content;/).then(x => x.closest('.monaco-editor'));

export const findAndSetEditorValue = async value => {
  const editor = await findMonacoEditor();
  const uri = editor.getAttribute('data-uri');

  window.monaco.editor.getModel(uri).setValue(value);
};

export const getEditorValue = async () => {
  const editor = await findMonacoEditor();
  const uri = editor.getAttribute('data-uri');

  return window.monaco.editor.getModel(uri).getValue();
};

const findTreeBody = () => screen.findByTestId('ide-tree-body', {}, { timeout: 5000 });

const findRootActions = () => screen.findByTestId('ide-root-actions', {}, { timeout: 7000 });

const findFileRowContainer = (row = null) =>
  row ? Promise.resolve(row.parentElement) : findTreeBody();

const findFileChild = async (row, name, index = 0) => {
  const container = await findFileRowContainer(row);
  const children = await findAllByText(container, name, { selector: '.file-row-name' });

  return children.map(x => x.closest('.file-row')).find(x => x.dataset.level === index.toString());
};

const openFileRow = row => {
  if (!row || isFolderRowOpen(row)) {
    return;
  }

  row.click();
};

const findAndTraverseToPath = async (path, index = 0, row = null) => {
  if (!path) {
    return row;
  }

  const [name, ...restOfPath] = path.split('/');

  openFileRow(row);

  const child = await findFileChild(row, name, index);

  return findAndTraverseToPath(restOfPath.join('/'), index + 1, child);
};

const clickFileRowAction = (row, name) => {
  fireEvent.mouseOver(row);

  const dropdownButton = getByLabelText(row, 'Create new file or directory');
  dropdownButton.click();

  const dropdownAction = getByLabelText(dropdownButton.parentNode, name);
  dropdownAction.click();
};

const findAndSetFileName = async value => {
  const nameField = await screen.findByTestId('file-name-field');
  fireEvent.input(nameField, { target: { value } });

  const createButton = screen.getByText('Create file');
  createButton.click();
};

const findAndClickRootAction = async name => {
  const container = await findRootActions();
  const button = getByLabelText(container, name);

  button.click();
};

export const openFile = async path => {
  const row = await findAndTraverseToPath(path);

  openFileRow(row);
};

export const createFile = async (path, content) => {
  const parentPath = path
    .split('/')
    .slice(0, -1)
    .join('/');

  const parentRow = await findAndTraverseToPath(parentPath);

  if (parentRow) {
    clickFileRowAction(parentRow, 'New file');
  } else {
    await findAndClickRootAction('New file');
  }

  await findAndSetFileName(path);
  await findAndSetEditorValue(content);
};

export const getFilesList = () => {
  return screen.getAllByTestId('file-row-name-container').map(e => e.textContent.trim());
};

export const deleteFile = async path => {
  const row = await findAndTraverseToPath(path);
  clickFileRowAction(row, 'Delete');
};

export const commit = async () => {
  clickOnLeftSidebarTab('Commit');
  screen.getByTestId('begin-commit-button').click();

  await screen.findByLabelText(/Commit to .+ branch/).then(x => x.click());

  screen.getByText('Commit').click();
};

export const createIdeComponent = (container, { isRepoEmpty = false, path = '' } = {}) => {
  global.jsdom.reconfigure({
    url: `${TEST_HOST}/-/ide/project/gitlab-test/lorem-ipsum${
      isRepoEmpty ? '-empty' : ''
    }/tree/master/-/${path}`,
  });

  const el = document.createElement('div');
  Object.assign(el.dataset, IDE_DATASET);
  container.appendChild(el);
  return initIde(el, { extendStore });
};
