import Vue from 'vue';
import { createTestingPinia } from '@pinia/testing';
import { PiniaVuePlugin } from 'pinia';
import { initViewSettings } from '~/rapid_diffs/app/view_settings';
import { setHTMLFixture } from 'helpers/fixtures';
import { useDiffsView } from '~/rapid_diffs/stores/diffs_view';
import { useDiffsList } from '~/rapid_diffs/stores/diffs_list';
import { DiffFile } from '~/rapid_diffs/diff_file';
import { COLLAPSE_FILE, EXPAND_FILE } from '~/rapid_diffs/events';

jest.mock('~/diffs/components/diff_app_controls.vue', () => ({
  props: jest.requireActual('~/diffs/components/diff_app_controls.vue').default.props,
  render(h) {
    return h('div', {
      attrs: {
        'data-diff-app-controls': JSON.stringify(true),
        'data-has-changes': JSON.stringify(this.hasChanges),
        'data-show-whitespace': JSON.stringify(this.showWhitespace),
        'data-diff-view-type': JSON.stringify(this.diffViewType),
        'data-is-loading': JSON.stringify(this.isLoading),
        'data-added-lines': JSON.stringify(this.addedLines),
        'data-removed-lines': JSON.stringify(this.removedLines),
        'data-diffs-count': JSON.stringify(this.diffsCount),
        'data-file-by-file-supported': JSON.stringify(this.fileByFileSupported),
        'data-hide-on-narrow-screen': JSON.stringify(this.hideOnNarrowScreen),
      },
    });
  },
  mounted() {
    this.$el.getInstance = () => this;
  },
}));

Vue.use(PiniaVuePlugin);

describe('View settings', () => {
  let pinia;
  let appData;

  const getDiffAppControls = () => document.querySelector('[data-diff-app-controls]');
  const getVueInstance = () => getDiffAppControls().getInstance();

  const init = () => {
    initViewSettings({ pinia, target: document.querySelector('[data-view-settings]'), appData });
  };

  beforeEach(() => {
    appData = {
      showWhitespace: true,
      diffViewType: 'parallel',
      updateUserEndpoint: '/update-user-endpoint',
    };
    setHTMLFixture(`
      <div
        data-view-settings
        data-show-whitespace="true"
        data-diff-view-type="parallel"
        data-update-user-endpoint="/update-user-endpoint"
      ></div>
    `);
    pinia = createTestingPinia();
  });

  it('sets initial state', () => {
    init();
    expect(useDiffsView().viewType).toBe('parallel');
    expect(useDiffsView().showWhitespace).toBe(true);
    expect(useDiffsView().updateUserEndpoint).toBe('/update-user-endpoint');
  });

  it('sets loaded files', () => {
    init();
    expect(useDiffsList().fillInLoadedFiles).toHaveBeenCalled();
  });

  it('renders diff app controls', () => {
    init();
    expect(getDiffAppControls()).not.toBe(null);
  });

  it('sets diff app controls props', () => {
    useDiffsList().loadedFiles = { foo: true };
    useDiffsView().diffsStats = {
      addedLines: 1,
      removedLines: 2,
      diffsCount: 3,
    };
    init();
    const el = getDiffAppControls();
    const getProp = (prop) => JSON.parse(el.dataset[prop]);
    expect(getProp('hasChanges')).toBe(true);
    expect(getProp('showWhitespace')).toBe(true);
    expect(getProp('diffViewType')).toBe('parallel');
    expect(getProp('isLoading')).toBe(false);
    expect(getProp('addedLines')).toBe(1);
    expect(getProp('removedLines')).toBe(2);
    expect(getProp('diffsCount')).toBe(3);
    expect(getProp('fileByFileSupported')).toBe(false);
    expect(getProp('hideOnNarrowScreen')).toBe(false);
  });

  it('triggers collapse all files', () => {
    const trigger = jest.fn();
    jest.spyOn(DiffFile, 'getAll').mockReturnValue([{ trigger }]);
    init();
    getVueInstance().$emit('collapseAllFiles');
    expect(trigger).toHaveBeenCalledWith(COLLAPSE_FILE);
  });

  it('triggers expand all files', () => {
    const trigger = jest.fn();
    jest.spyOn(DiffFile, 'getAll').mockReturnValue([{ trigger }]);
    init();
    getVueInstance().$emit('expandAllFiles');
    expect(trigger).toHaveBeenCalledWith(EXPAND_FILE);
  });

  it('updates view type', async () => {
    init();
    await getVueInstance().$emit('updateDiffViewType', 'inline');
    expect(useDiffsView().updateViewType).toHaveBeenCalledWith('inline');
  });

  it('toggles whitespace', async () => {
    init();
    await getVueInstance().$emit('toggleWhitespace', false);
    expect(useDiffsView().updateShowWhitespace).toHaveBeenCalledWith(false);
  });
});
