import { mount } from '@vue/test-utils';
import { GlIcon } from '@gitlab/ui';
import Vue, { nextTick } from 'vue';
import { trimText } from 'helpers/text_helper';
import waitForPromises from 'helpers/wait_for_promises';
import ListItem from '~/ide/components/commit_sidebar/list_item.vue';
import { createRouter } from '~/ide/ide_router';
import { createStore } from '~/ide/stores';
import { file } from '../../helpers';

describe('Multi-file editor commit sidebar list item', () => {
  let wrapper;
  let f;
  let findPathEl;
  let store;
  let router;

  beforeEach(() => {
    store = createStore();
    jest.spyOn(store, 'dispatch');

    router = createRouter(store);

    f = file('test-file');

    store.state.entries[f.path] = f;

    wrapper = mount(ListItem, {
      store,
      propsData: {
        file: f,
        activeFileKey: `staged-${f.key}`,
      },
    });

    findPathEl = wrapper.find('.multi-file-commit-list-path');
  });

  afterEach(() => {
    wrapper.destroy();
  });

  const findPathText = () => trimText(findPathEl.text());

  it('renders file path', () => {
    expect(findPathText()).toContain(f.path);
  });

  it('correctly renders renamed entries', async () => {
    Vue.set(f, 'prevName', 'Old name');
    await nextTick();

    expect(findPathText()).toEqual(`Old name → ${f.name}`);
  });

  it('correctly renders entry, the name of which did not change after rename (as within a folder)', async () => {
    Vue.set(f, 'prevName', f.name);
    await nextTick();

    expect(findPathText()).toEqual(f.name);
  });

  it('opens a closed file in the editor when clicking the file path', async () => {
    jest.spyOn(router, 'push').mockImplementation(() => {});

    await findPathEl.trigger('click');

    expect(store.dispatch).toHaveBeenCalledWith('openPendingTab', expect.anything());
    expect(router.push).toHaveBeenCalled();
  });

  it('calls updateViewer with diff when clicking file', async () => {
    jest.spyOn(router, 'push').mockImplementation(() => {});

    await findPathEl.trigger('click');
    await waitForPromises();

    expect(store.dispatch).toHaveBeenCalledWith('updateViewer', 'diff');
  });

  describe('icon name', () => {
    const getIconName = () => wrapper.findComponent(GlIcon).props('name');

    it('is modified when not a tempFile', () => {
      expect(getIconName()).toBe('file-modified');
    });

    it('is addition when is a tempFile', async () => {
      f.tempFile = true;
      await nextTick();

      expect(getIconName()).toBe('file-addition');
    });

    it('is deletion when is deleted', async () => {
      f.deleted = true;
      await nextTick();

      expect(getIconName()).toBe('file-deletion');
    });
  });

  describe('icon class', () => {
    const getIconClass = () => wrapper.findComponent(GlIcon).classes();

    it('is modified when not a tempFile', () => {
      expect(getIconClass()).toContain('ide-file-modified');
    });

    it('is addition when is a tempFile', async () => {
      f.tempFile = true;
      await nextTick();

      expect(getIconClass()).toContain('ide-file-addition');
    });

    it('returns deletion when is deleted', async () => {
      f.deleted = true;
      await nextTick();

      expect(getIconClass()).toContain('ide-file-deletion');
    });
  });

  describe('is active', () => {
    it('does not add active class when dont keys match', () => {
      expect(wrapper.find('.is-active').exists()).toBe(false);
    });

    it('adds active class when keys match', async () => {
      await wrapper.setProps({ keyPrefix: 'staged' });

      expect(wrapper.find('.is-active').exists()).toBe(true);
    });
  });
});
