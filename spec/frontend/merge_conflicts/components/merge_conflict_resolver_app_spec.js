import { GlSprintf } from '@gitlab/ui';
import { shallowMount, createLocalVue } from '@vue/test-utils';
import Vuex from 'vuex';
import InlineConflictLines from '~/merge_conflicts/components/inline_conflict_lines.vue';
import ParallelConflictLines from '~/merge_conflicts/components/parallel_conflict_lines.vue';
import component from '~/merge_conflicts/merge_conflict_resolver_app.vue';
import { createStore } from '~/merge_conflicts/store';
import { decorateFiles } from '~/merge_conflicts/utils';
import { conflictsMock } from '../mock_data';

const localVue = createLocalVue();
localVue.use(Vuex);

describe('Merge Conflict Resolver App', () => {
  let wrapper;
  let store;

  const decoratedMockFiles = decorateFiles(conflictsMock.files);

  const mountComponent = () => {
    wrapper = shallowMount(component, {
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

  afterEach(() => {
    wrapper.destroy();
  });

  const findConflictsCount = () => wrapper.find('[data-testid="conflicts-count"]');
  const findFiles = () => wrapper.findAll('[data-testid="files"]');
  const findFileHeader = (w = wrapper) => w.find('[data-testid="file-name"]');
  const findFileInteractiveButton = (w = wrapper) => w.find('[data-testid="interactive-button"]');
  const findFileInlineButton = (w = wrapper) => w.find('[data-testid="inline-button"]');
  const findSideBySideButton = () => wrapper.find('[data-testid="side-by-side"]');
  const findInlineConflictLines = (w = wrapper) => w.find(InlineConflictLines);
  const findParallelConflictLines = (w = wrapper) => w.find(ParallelConflictLines);
  const findCommitMessageTextarea = () => wrapper.find('[data-testid="commit-message"]');

  it('shows the amount of conflicts', () => {
    mountComponent();

    const title = findConflictsCount();

    expect(title.exists()).toBe(true);
    expect(title.text().trim()).toBe('Showing 3 conflicts between test-conflicts and main');
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
        await wrapper.vm.$nextTick();

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
        await wrapper.vm.$nextTick();

        const parallelConflictLinesComponent = findParallelConflictLines(findFiles().at(0));

        expect(parallelConflictLinesComponent.exists()).toBe(true);
        expect(parallelConflictLinesComponent.props('file')).toEqual(decoratedMockFiles[0]);
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
