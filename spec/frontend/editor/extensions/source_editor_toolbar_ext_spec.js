import Vue from 'vue';
import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import SourceEditorToolbar from '~/editor/components/source_editor_toolbar.vue';
import { ToolbarExtension } from '~/editor/extensions/source_editor_toolbar_ext';
import EditorInstance from '~/editor/source_editor_instance';
import { apolloProvider } from '~/editor/components/source_editor_toolbar_graphql';
import { buildButton, warmUpCacheWithItems } from '../components/helpers';

describe('Source Editor Toolbar Extension', () => {
  let instance;

  const createInstance = (baseInstance = {}) => {
    return new EditorInstance(baseInstance);
  };
  const getDefaultEl = () => document.getElementById('editor-toolbar');
  const getCustomEl = () => document.getElementById('custom-toolbar');
  const item1 = buildButton('foo');
  const item2 = buildButton('bar');

  beforeEach(() => {
    setHTMLFixture('<div id="editor-toolbar"></div><div id="custom-toolbar"></div>');
  });

  afterEach(() => {
    apolloProvider.defaultClient.clearStore();
    resetHTMLFixture();
  });

  describe('onSetup', () => {
    beforeEach(() => {
      instance = createInstance();
    });

    it.each`
      id                  | type         | prefix               | expectedElFn
      ${undefined}        | ${'default'} | ${'Sets up'}         | ${getDefaultEl}
      ${'custom-toolbar'} | ${'custom'}  | ${'Sets up'}         | ${getCustomEl}
      ${'non-existing'}   | ${'default'} | ${'Does not set up'} | ${getDefaultEl}
    `('Sets up the Vue application on $type node when node is $id', ({ id, expectedElFn }) => {
      jest.spyOn(Vue, 'extend');
      jest.spyOn(ToolbarExtension, 'setupVue');

      const el = document.getElementById(id);
      const expectedEl = expectedElFn();

      instance.use({ definition: ToolbarExtension, setupOptions: { el } });

      if (expectedEl) {
        expect(ToolbarExtension.setupVue).toHaveBeenCalledWith(expectedEl);
        expect(Vue.extend).toHaveBeenCalledWith(SourceEditorToolbar);
      } else {
        expect(ToolbarExtension.setupVue).not.toHaveBeenCalled();
      }
    });
  });

  describe('public API', () => {
    beforeEach(async () => {
      await warmUpCacheWithItems();
      instance = createInstance();
      instance.use({ definition: ToolbarExtension });
    });

    describe('getAllItems', () => {
      it('returns the list of all toolbar items', async () => {
        await expect(instance.toolbar.getAllItems()).toEqual([]);
        await warmUpCacheWithItems([item1, item2]);
        await expect(instance.toolbar.getAllItems()).toEqual([item1, item2]);
      });
    });

    describe('getItem', () => {
      it('returns a toolbar item by id', async () => {
        await expect(instance.toolbar.getItem(item1.id)).toEqual(undefined);
        await warmUpCacheWithItems([item1]);
        await expect(instance.toolbar.getItem(item1.id)).toEqual(item1);
      });
    });

    describe('addItems', () => {
      it.each`
        idsToAdd                | itemsToAdd        | expectedResult
        ${'empty array'}        | ${[]}             | ${[]}
        ${'undefined'}          | ${undefined}      | ${[]}
        ${item2.id}             | ${[item2]}        | ${[item2]}
        ${item1.id}             | ${[item1]}        | ${[item1]}
        ${[item1.id, item2.id]} | ${[item1, item2]} | ${[item1, item2]}
      `('adds $idsToAdd item(s) to cache', async ({ itemsToAdd, expectedResult }) => {
        await instance.toolbar.addItems(itemsToAdd);
        await expect(instance.toolbar.getAllItems()).toEqual(expectedResult);
      });

      it('correctly adds items to the pre-populated cache', async () => {
        await warmUpCacheWithItems([item1]);
        await instance.toolbar.addItems([item2]);
        await expect(instance.toolbar.getAllItems()).toEqual([item1, item2]);
      });

      it('does not fail if the item is an Object', async () => {
        await instance.toolbar.addItems(item1);
        await expect(instance.toolbar.getAllItems()).toEqual([item1]);
      });
    });

    describe('removeItems', () => {
      beforeEach(async () => {
        await warmUpCacheWithItems([item1, item2]);
      });

      it.each`
        idsToRemove             | expectedResult
        ${undefined}            | ${[item1, item2]}
        ${[]}                   | ${[item1, item2]}
        ${[item1.id]}           | ${[item2]}
        ${[item2.id]}           | ${[item1]}
        ${[item1.id, item2.id]} | ${[]}
      `(
        'successfully removes $idsToRemove from [foo, bar]',
        async ({ idsToRemove, expectedResult }) => {
          await instance.toolbar.removeItems(idsToRemove);
          await expect(instance.toolbar.getAllItems()).toEqual(expectedResult);
        },
      );
    });

    describe('updateItem', () => {
      const updatedProp = {
        icon: 'book',
      };

      beforeEach(async () => {
        await warmUpCacheWithItems([item1, item2]);
      });

      it.each`
        itemsToUpdate | idToUpdate     | propsToUpdate  | expectedResult
        ${undefined}  | ${'undefined'} | ${undefined}   | ${[item1, item2]}
        ${item2.id}   | ${item2.id}    | ${undefined}   | ${[item1, item2]}
        ${item2.id}   | ${item2.id}    | ${{}}          | ${[item1, item2]}
        ${[item1]}    | ${item1.id}    | ${updatedProp} | ${[{ ...item1, ...updatedProp }, item2]}
        ${[item2]}    | ${item2.id}    | ${updatedProp} | ${[item1, { ...item2, ...updatedProp }]}
      `(
        'updates $idToUpdate item in cache with $propsToUpdate',
        async ({ idToUpdate, propsToUpdate, expectedResult }) => {
          await instance.toolbar.updateItem(idToUpdate, propsToUpdate);
          await expect(instance.toolbar.getAllItems()).toEqual(expectedResult);
          if (propsToUpdate) {
            await expect(instance.toolbar.getItem(idToUpdate)).toEqual(
              expect.objectContaining(propsToUpdate),
            );
          }
        },
      );
    });
  });
});
