import { builders } from 'prosemirror-test-builder';
import DescriptionList from '~/content_editor/extensions/description_list';
import DescriptionItem from '~/content_editor/extensions/description_item';
import { createTestEditor, triggerKeyboardInput } from '../test_utils';

describe('content_editor/extensions/description_item', () => {
  let tiptapEditor;
  let doc;
  let p;
  let descriptionList;
  let descriptionItem;

  beforeEach(() => {
    tiptapEditor = createTestEditor({ extensions: [DescriptionList, DescriptionItem] });

    ({ doc, paragraph: p, descriptionList, descriptionItem } = builders(tiptapEditor.schema));
  });

  describe('shortcut: Enter', () => {
    it('splits a description item into two items', () => {
      const initialDoc = doc(descriptionList(descriptionItem(p('Description item'))));
      const expectedDoc = doc(
        descriptionList(descriptionItem(p('Descrip')), descriptionItem(p('tion item'))),
      );

      tiptapEditor.commands.setContent(initialDoc.toJSON());
      tiptapEditor.commands.setTextSelection(10);
      tiptapEditor.commands.keyboardShortcut('Enter');

      expect(tiptapEditor.getJSON()).toEqual(expectedDoc.toJSON());
    });
  });

  describe('shortcut: Tab', () => {
    it('converts a description term into a description details', () => {
      const initialDoc = doc(descriptionList(descriptionItem(p('Description item'))));
      const expectedDoc = doc(
        descriptionList(descriptionItem({ isTerm: false }, p('Description item'))),
      );

      tiptapEditor.commands.setContent(initialDoc.toJSON());
      tiptapEditor.commands.setTextSelection(10);
      tiptapEditor.commands.keyboardShortcut('Tab');

      expect(tiptapEditor.getJSON()).toEqual(expectedDoc.toJSON());
    });

    it('has no effect on a description details', () => {
      const initialDoc = doc(
        descriptionList(descriptionItem({ isTerm: false }, p('Description item'))),
      );

      tiptapEditor.commands.setContent(initialDoc.toJSON());
      tiptapEditor.commands.setTextSelection(10);
      tiptapEditor.commands.keyboardShortcut('Tab');

      expect(tiptapEditor.getJSON()).toEqual(initialDoc.toJSON());
    });
  });

  describe('shortcut: Shift-Tab', () => {
    it('converts a description details into a description term', () => {
      const initialDoc = doc(
        descriptionList(
          descriptionItem({ isTerm: false }, p('Description item')),
          descriptionItem(p('Description item')),
          descriptionItem(p('Description item')),
        ),
      );
      const expectedDoc = doc(
        descriptionList(
          descriptionItem(p('Description item')),
          descriptionItem(p('Description item')),
          descriptionItem(p('Description item')),
        ),
      );

      tiptapEditor.commands.setContent(initialDoc.toJSON());
      tiptapEditor.commands.setTextSelection(10);
      tiptapEditor.commands.keyboardShortcut('Shift-Tab');

      expect(tiptapEditor.getJSON()).toEqual(expectedDoc.toJSON());
    });

    it('lifts a description term', () => {
      const initialDoc = doc(descriptionList(descriptionItem(p('Description item'))));
      const expectedDoc = doc(p('Description item'));

      tiptapEditor.commands.setContent(initialDoc.toJSON());
      tiptapEditor.commands.setTextSelection(10);
      tiptapEditor.commands.keyboardShortcut('Shift-Tab');

      expect(tiptapEditor.getJSON()).toEqual(expectedDoc.toJSON());
    });
  });

  describe('capturing keyboard events', () => {
    it.each`
      key      | shiftKey | nodeActive | captured | description
      ${'Tab'} | ${false} | ${true}    | ${true}  | ${'captures Tab key when cursor is inside a description item'}
      ${'Tab'} | ${false} | ${false}   | ${false} | ${'does not capture Tab key when cursor is not inside a description item'}
      ${'Tab'} | ${true}  | ${true}    | ${true}  | ${'captures Shift-Tab key when cursor is inside a description item'}
      ${'Tab'} | ${true}  | ${false}   | ${false} | ${'does not capture Shift-Tab key when cursor is not inside a description item'}
    `('$description', ({ key, shiftKey, nodeActive, captured }) => {
      const initialDoc = doc(descriptionList(descriptionItem(p('Text content'))));

      tiptapEditor.commands.setContent(initialDoc.toJSON());

      jest.spyOn(tiptapEditor, 'isActive').mockReturnValue(nodeActive);

      expect(triggerKeyboardInput({ tiptapEditor, key, shiftKey })).toBe(captured);
    });
  });
});
