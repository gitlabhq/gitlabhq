import { GlSprintf } from '@gitlab/ui';
import Vue, { nextTick } from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import { shallowMountExtended, extendedWrapper } from 'helpers/vue_test_utils_helper';
import InlineConflictLines from '~/merge_conflicts/components/inline_conflict_lines.vue';
import ParallelConflictLines from '~/merge_conflicts/components/parallel_conflict_lines.vue';
import component from '~/merge_conflicts/merge_conflict_resolver_app.vue';
import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';
import { createStore } from '~/merge_conflicts/store';
import { decorateFiles } from '~/merge_conflicts/utils';
import { conflictsMock } from '../mock_data';

Vue.use(Vuex);

describe('Merge Conflict Resolver App', () => {
  let wrapper;
  let store;

  const decoratedMockFiles = decorateFiles(conflictsMock);

  const mountComponent = () => {
    wrapper = shallowMountExtended(component, {
      store,
      stubs: { GlSprintf },
      provide() {
        return {
          mergeRequestPath: 'foo',
          sourceBranchPath: 'foo',
          resolveConflictsPath: 'bar',
        };
      },
    });
  };

  beforeEach(() => {
    store = createStore();
    store.commit('SET_LOADING_STATE', false);
    store.dispatch('setConflictsData', conflictsMock);
  });

  const findLoadingSpinner = () => wrapper.findByTestId('loading-spinner');
  const findConflictsCount = () => wrapper.findByTestId('conflicts-count');
  const findFiles = () => wrapper.findAllByTestId('files');
  const findFileHeader = (w = wrapper) => extendedWrapper(w).findByTestId('file-name');
  const findFileInteractiveButton = (w = wrapper) =>
    extendedWrapper(w).findByTestId('interactive-button');
  const findFileInlineButton = (w = wrapper) => extendedWrapper(w).findByTestId('inline-button');
  const findSideBySideButton = () => wrapper.findByTestId('side-by-side');
  const findInlineConflictLines = (w = wrapper) => w.findComponent(InlineConflictLines);
  const findParallelConflictLines = (w = wrapper) => w.findComponent(ParallelConflictLines);
  const findCommitMessageTextarea = () => wrapper.findByTestId('commit-message');
  const findClipboardButton = (w = wrapper) => w.findComponent(ClipboardButton);

  it('shows the amount of conflicts', () => {
    mountComponent();

    const title = findConflictsCount();

    expect(title.exists()).toBe(true);
    expect(title.text().trim()).toBe('Showing 3 conflicts');
  });

  it('shows a loading spinner while loading', () => {
    store.commit('SET_LOADING_STATE', true);
    mountComponent();

    expect(findLoadingSpinner().exists()).toBe(true);
  });

  it('does not show a loading spinner once loaded', () => {
    mountComponent();

    expect(findLoadingSpinner().exists()).toBe(false);
  });

  describe('files', () => {
    it('shows one file area for each file', () => {
      mountComponent();

      expect(findFiles()).toHaveLength(conflictsMock.files.length);
    });

    it('has the appropriate file header', () => {
      mountComponent();

      const fileHeader = findFileHeader(findFiles().at(0));

      expect(fileHeader.text()).toBe(decoratedMockFiles[0].filePath);
    });

    describe('editing', () => {
      it('interactive mode is the default', () => {
        mountComponent();

        const interactiveButton = findFileInteractiveButton(findFiles().at(0));
        const inlineButton = findFileInlineButton(findFiles().at(0));

        expect(interactiveButton.props('selected')).toBe(true);
        expect(inlineButton.props('selected')).toBe(false);
      });

      it('clicking inline set inline as default', async () => {
        mountComponent();

        const inlineButton = findFileInlineButton(findFiles().at(0));
        expect(inlineButton.props('selected')).toBe(false);

        inlineButton.vm.$emit('click');
        await nextTick();

        expect(inlineButton.props('selected')).toBe(true);
      });

      it('inline mode shows a inline-conflict-lines', () => {
        mountComponent();

        const inlineConflictLinesComponent = findInlineConflictLines(findFiles().at(0));

        expect(inlineConflictLinesComponent.exists()).toBe(true);
        expect(inlineConflictLinesComponent.props('file')).toEqual(decoratedMockFiles[0]);
      });

      it('parallel mode shows a parallel-conflict-lines', async () => {
        mountComponent();

        findSideBySideButton().vm.$emit('click');
        await nextTick();

        const parallelConflictLinesComponent = findParallelConflictLines(findFiles().at(0));

        expect(parallelConflictLinesComponent.exists()).toBe(true);
        expect(parallelConflictLinesComponent.props('file')).toEqual(decoratedMockFiles[0]);
      });
    });

    describe('clipboard button', () => {
      it('exists', () => {
        mountComponent();
        expect(findClipboardButton().exists()).toBe(true);
      });

      it('has the correct props', () => {
        mountComponent();
        expect(findClipboardButton().attributes()).toMatchObject({
          text: decoratedMockFiles[0].filePath,
          title: 'Copy file path',
        });
      });
    });
  });

  describe('submit form', () => {
    it('contains a commit message textarea', () => {
      mountComponent();

      expect(findCommitMessageTextarea().exists()).toBe(true);
    });
  });
});
