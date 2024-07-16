import { builders } from 'prosemirror-test-builder';
import DescriptionList from '~/content_editor/extensions/description_list';
import DescriptionItem from '~/content_editor/extensions/description_item';
import { createTestEditor, triggerNodeInputRule } from '../test_utils';

describe('content_editor/extensions/description_list', () => {
  let tiptapEditor;
  let doc;
  let p;
  let descriptionList;
  let descriptionItem;

  beforeEach(() => {
    tiptapEditor = createTestEditor({ extensions: [DescriptionList, DescriptionItem] });

    ({ doc, paragraph: p, descriptionList, descriptionItem } = builders(tiptapEditor.schema));
  });

  it.each`
    inputRuleText | insertedNode                                   | insertedNodeType
    ${'<dl>'}     | ${() => descriptionList(descriptionItem(p()))} | ${'descriptionList'}
    ${'<dl'}      | ${() => p()}                                   | ${'paragraph'}
    ${'dl>'}      | ${() => p()}                                   | ${'paragraph'}
  `('with input=$input, it inserts a $insertedNodeType node', ({ inputRuleText, insertedNode }) => {
    triggerNodeInputRule({ tiptapEditor, inputRuleText });

    expect(tiptapEditor.getJSON()).toEqual(doc(insertedNode()).toJSON());
  });
});
