import {
  findAllByText,
  fireEvent,
  getByLabelText,
  findByTestId,
  getByText,
  screen,
  findByText,
} from '@testing-library/dom';
import { editor as monacoEditor } from 'monaco-editor';

const isFolderRowOpen = (row) => row.matches('.folder.is-open');

const getLeftSidebar = () => screen.getByTestId('left-sidebar');

export const switchLeftSidebarTab = (name) => {
  const sidebar = getLeftSidebar();

  const button = getByLabelText(sidebar, name);

  button.click();
};

export const getStatusBar = () => document.querySelector('.ide-status-bar');

export const waitForMonacoEditor = () =>
  new Promise((resolve) => {
    monacoEditor.onDidCreateEditor(resolve);
  });

export const waitForEditorDispose = (instance) =>
  new Promise((resolve) => {
    instance.onDidDispose(resolve);
  });

export const waitForEditorModelChange = (instance) =>
  new Promise((resolve) => {
    instance.onDidChangeModel(resolve);
  });

export const findMonacoEditor = () =>
  screen.findAllByLabelText(/Editor content;/).then(([x]) => x.closest('.monaco-editor'));

export const findMonacoDiffEditor = () =>
  screen.findAllByLabelText(/Editor content;/).then(([x]) => x.closest('.monaco-diff-editor'));

export const findAndSetEditorValue = async (value) => {
  const editor = await findMonacoEditor();
  const { uri } = editor.dataset;

  monacoEditor.getModel(uri).setValue(value);
};

export const getEditorValue = async () => {
  const editor = await findMonacoEditor();
  const { uri } = editor.dataset;

  return monacoEditor.getModel(uri).getValue();
};

const findTreeBody = () => screen.findByTestId('ide-tree-body');

const findRootActions = () => screen.findByTestId('ide-root-actions');

const findFileRowContainer = (row = null) =>
  row ? Promise.resolve(row.parentElement) : findTreeBody();

const findFileChild = async (row, name, index = 0) => {
  const container = await findFileRowContainer(row);
  const children = await findAllByText(container, name, { selector: '.file-row-name' });

  return children
    .map((x) => x.closest('.file-row'))
    .find((x) => x.dataset.level === index.toString());
};

const openFileRow = (row) => {
  if (!row || isFolderRowOpen(row)) {
    return;
  }

  row.click();
};

export const findAndTraverseToPath = async (path, index = 0, row = null) => {
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

const fillFileNameModal = async (value, submitText = 'Create file') => {
  const modal = await screen.findByTestId('ide-new-entry');

  const nameField = await findByTestId(modal, 'file-name-field');
  fireEvent.input(nameField, { target: { value } });

  const createButton = getByText(modal, submitText, { selector: 'button > span' });
  createButton.click();
};

const findAndClickRootAction = async (name) => {
  const container = await findRootActions();
  const button = getByLabelText(container, name);

  button.click();
};

/**
 * Drop leading "/-/ide" and file path from the current URL
 */
export const getBaseRoute = (url = window.location.pathname) =>
  url.replace(/^\/-\/ide/, '').replace(/\/-\/.*$/, '');

export const clickPreviewMarkdown = () => {
  screen.getByText('Preview Markdown').click();
};

export const openFile = async (path) => {
  const row = await findAndTraverseToPath(path);

  openFileRow(row);
};

export const waitForTabToOpen = (fileName) =>
  findByText(document.querySelector('.multi-file-edit-pane'), fileName);

export const createFile = async (path, content) => {
  const parentPath = path.split('/').slice(0, -1).join('/');

  const parentRow = await findAndTraverseToPath(parentPath);

  if (parentRow) {
    clickFileRowAction(parentRow, 'New file');
  } else {
    await findAndClickRootAction('New file');
  }

  await fillFileNameModal(path);
  await findAndSetEditorValue(content);
};

export const updateFile = async (path, content) => {
  await openFile(path);
  await findAndSetEditorValue(content);
};

export const getFilesList = () => {
  return screen.getAllByTestId('file-row-name-container').map((e) => e.textContent.trim());
};

export const deleteFile = async (path) => {
  const row = await findAndTraverseToPath(path);
  clickFileRowAction(row, 'Delete');
};

export const renameFile = async (path, newPath) => {
  const row = await findAndTraverseToPath(path);
  clickFileRowAction(row, 'Rename/Move');

  await fillFileNameModal(newPath, 'Rename file');
};

export const closeFile = async (path) => {
  const button = await screen.getByLabelText(`Close ${path}`, {
    selector: '.multi-file-tabs button',
  });

  button.click();
};

/**
 * Fill out and submit the commit form in the Web IDE
 *
 * @param {Object} options - Used to fill out the commit form in the IDE
 * @param {Boolean} options.newBranch - Flag for the "Create a new branch" radio.
 * @param {Boolean} options.newMR - Flag for the "Start a new merge request" checkbox.
 * @param {String} options.newBranchName - Value to put in the new branch name input field. The Web IDE supports leaving this field blank.
 */
export const commit = async ({ newBranch = false, newMR = false, newBranchName = '' } = {}) => {
  switchLeftSidebarTab('Commit');
  screen.getByTestId('begin-commit-button').click();

  await waitForMonacoEditor();

  const mrCheck = await screen.findByLabelText('Start a new merge request');
  if (Boolean(mrCheck.checked) !== newMR) {
    mrCheck.click();
  }

  if (!newBranch) {
    const option = await screen.findByLabelText(/Commit to .+ branch/);
    await option.click();
  } else {
    const option = await screen.findByLabelText('Create a new branch');
    await option.click();

    const branchNameInput = await screen.findByTestId('ide-new-branch-name');
    fireEvent.input(branchNameInput, { target: { value: newBranchName } });
  }

  screen.getByText('Commit').click();

  await waitForMonacoEditor();
};
