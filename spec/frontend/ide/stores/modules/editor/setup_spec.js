import { cloneDeep } from 'lodash';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import eventHub from '~/ide/eventhub';
import { createStoreOptions } from '~/ide/stores';
import { setupFileEditorsSync } from '~/ide/stores/modules/editor/setup';
import { createTriggerRenamePayload, createTriggerUpdatePayload } from '../../../helpers';

describe('~/ide/stores/modules/editor/setup', () => {
  let store;

  beforeEach(() => {
    store = new Vuex.Store(createStoreOptions());
    store.state.entries = {
      foo: {},
      bar: {},
    };
    store.state.editor.fileEditors = {
      foo: {},
      bizz: {},
    };

    setupFileEditorsSync(store);
  });

  it('when files change is emitted, removes unused fileEditors', () => {
    eventHub.$emit('ide.files.change');

    expect(store.state.entries).toEqual({
      foo: {},
      bar: {},
    });
    expect(store.state.editor.fileEditors).toEqual({
      foo: {},
    });
  });

  it('when files update is emitted, does nothing', () => {
    const origState = cloneDeep(store.state);

    eventHub.$emit('ide.files.change', createTriggerUpdatePayload('foo'));

    expect(store.state).toEqual(origState);
  });

  it('when files rename is emitted, renames fileEditor', () => {
    eventHub.$emit('ide.files.change', createTriggerRenamePayload('foo', 'foo_new'));

    expect(store.state.editor.fileEditors).toEqual({
      foo_new: {},
      bizz: {},
    });
  });
});
