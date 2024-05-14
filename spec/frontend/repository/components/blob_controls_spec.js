import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';

import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import BlobControls from '~/repository/components/blob_controls.vue';
import blobControlsQuery from '~/repository/queries/blob_controls.query.graphql';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createRouter from '~/repository/router';
import { updateElementsVisibility } from '~/repository/utils/dom';
import { resetShortcutsForTests } from '~/behaviors/shortcuts';
import ShortcutsBlob from '~/behaviors/shortcuts/shortcuts_blob';
import Shortcuts from '~/behaviors/shortcuts/shortcuts';
import BlobLinePermalinkUpdater from '~/blob/blob_line_permalink_updater';
import { blobControlsDataMock, refMock } from '../mock_data';

jest.mock('~/repository/utils/dom');
jest.mock('~/behaviors/shortcuts/shortcuts_blob');
jest.mock('~/blob/blob_line_permalink_updater');

let router;
let wrapper;
let mockResolver;

const createComponent = async () => {
  Vue.use(VueApollo);

  const project = { ...blobControlsDataMock };
  const projectPath = 'some/project';

  router = createRouter(projectPath, refMock);

  router.replace({ name: 'blobPath', params: { path: '/some/file.js' } });

  mockResolver = jest.fn().mockResolvedValue({ data: { project } });

  await resetShortcutsForTests();

  wrapper = shallowMountExtended(BlobControls, {
    router,
    apolloProvider: createMockApollo([[blobControlsQuery, mockResolver]]),
    propsData: { projectPath },
    mixins: [{ data: () => ({ ref: refMock }) }],
  });

  await waitForPromises();
};

describe('Blob controls component', () => {
  const findFindButton = () => wrapper.findByTestId('find');
  const findBlameButton = () => wrapper.findByTestId('blame');
  const findHistoryButton = () => wrapper.findByTestId('history');
  const findPermalinkButton = () => wrapper.findByTestId('permalink');

  beforeEach(() => createComponent());

  it('triggers a `focusSearchFile` shortcut when the findFile button is clicked', () => {
    const findFileButton = findFindButton();
    jest.spyOn(Shortcuts, 'focusSearchFile').mockResolvedValue();
    findFileButton.vm.$emit('click');

    expect(Shortcuts.focusSearchFile).toHaveBeenCalled();
  });

  it('renders a blame button with the correct href', () => {
    expect(findBlameButton().attributes('href')).toBe('blame/file.js');
  });

  it('renders a history button with the correct href', () => {
    expect(findHistoryButton().attributes('href')).toBe('history/file.js');
  });

  it('renders a permalink button with the correct href', () => {
    expect(findPermalinkButton().attributes('href')).toBe('permalink/file.js');
  });

  it.each`
    name                 | path
    ${'blobPathDecoded'} | ${null}
    ${'treePathDecoded'} | ${'myFile.js'}
  `(
    'does not render any buttons if router name is $name and router path is $path',
    async ({ name, path }) => {
      router.replace({ name, params: { path } });

      await nextTick();

      expect(findFindButton().exists()).toBe(false);
      expect(findBlameButton().exists()).toBe(false);
      expect(findHistoryButton().exists()).toBe(false);
      expect(findPermalinkButton().exists()).toBe(false);
      expect(updateElementsVisibility).toHaveBeenCalledWith('.tree-controls', true);
    },
  );

  it('loads the ShortcutsBlob', () => {
    expect(ShortcutsBlob).toHaveBeenCalled();
  });

  it('loads the BlobLinePermalinkUpdater', () => {
    expect(BlobLinePermalinkUpdater).toHaveBeenCalled();
  });
});
