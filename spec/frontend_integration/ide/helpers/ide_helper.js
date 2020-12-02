import {
  findAllByText,
  fireEvent,
  getByLabelText,
  findByTestId,
  getByText,
  screen,
} from '@testing-library/dom';

const isFolderRowOpen = row => row.matches('.folder.is-open');

const getLeftSidebar = () => screen.getByTestId('left-sidebar');

const clickOnLeftSidebarTab = name => {
  const sidebar = getLeftSidebar();

  const button = getByLabelText(sidebar, name);

  button.click();
};

export const getStatusBar = () => document.querySelector('.ide-status-bar');

export const waitForMonacoEditor = () =>
  new Promise(resolve => window.monaco.editor.onDidCreateEditor(resolve));

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

const fillFileNameModal = async (value, submitText = 'Create file') => {
  const modal = await screen.findByTestId('ide-new-entry');

  const nameField = await findByTestId(modal, 'file-name-field');
  fireEvent.input(nameField, { target: { value } });

  const createButton = getByText(modal, submitText, { selector: 'button' });
  createButton.click();
};

const findAndClickRootAction = async name => {
  const container = await findRootActions();
  const button = getByLabelText(container, name);

  button.click();
};

export const clickPreviewMarkdown = () => {
  screen.getByText('Preview Markdown').click();
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

  await fillFileNameModal(path);
  await findAndSetEditorValue(content);
};

export const getFilesList = () => {
  return screen.getAllByTestId('file-row-name-container').map(e => e.textContent.trim());
};

export const deleteFile = async path => {
  const row = await findAndTraverseToPath(path);
  clickFileRowAction(row, 'Delete');
};

export const renameFile = async (path, newPath) => {
  const row = await findAndTraverseToPath(path);
  clickFileRowAction(row, 'Rename/Move');

  await fillFileNameModal(newPath, 'Rename file');
};

export const closeFile = async path => {
  const button = await screen.getByLabelText(`Close ${path}`, {
    selector: '.multi-file-tabs button',
  });

  button.click();
};

export const commit = async () => {
  clickOnLeftSidebarTab('Commit');
  screen.getByTestId('begin-commit-button').click();

  await screen.findByLabelText(/Commit to .+ branch/).then(x => x.click());

  screen.getByText('Commit').click();
};
