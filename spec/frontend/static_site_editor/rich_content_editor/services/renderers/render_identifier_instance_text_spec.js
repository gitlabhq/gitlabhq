import { buildUneditableInlineTokens } from '~/static_site_editor/rich_content_editor/services/renderers/build_uneditable_token';
import renderer from '~/static_site_editor/rich_content_editor/services/renderers/render_identifier_instance_text';

import { buildMockTextNode, normalTextNode } from './mock_data';

const mockTextStart = 'Majority example ';
const mockTextMiddle = '[environment terraform plans][terraform]';
const mockTextEnd = '.';
const identifierInstanceStartTextNode = buildMockTextNode(mockTextStart);
const identifierInstanceEndTextNode = buildMockTextNode(mockTextEnd);

describe('Render Identifier Instance Text renderer', () => {
  describe('canRender', () => {
    it.each`
      node                                                                     | target
      ${normalTextNode}                                                        | ${false}
      ${identifierInstanceStartTextNode}                                       | ${false}
      ${identifierInstanceEndTextNode}                                         | ${false}
      ${buildMockTextNode(mockTextMiddle)}                                     | ${true}
      ${buildMockTextNode('Minority example [environment terraform plans][]')} | ${true}
      ${buildMockTextNode('Minority example [environment terraform plans]')}   | ${true}
    `(
      'should return $target when the $node validates against identifier instance syntax',
      ({ node, target }) => {
        expect(renderer.canRender(node)).toBe(target);
      },
    );
  });

  describe('render', () => {
    it.each`
      start            | middle                               | end
      ${mockTextStart} | ${mockTextMiddle}                    | ${mockTextEnd}
      ${mockTextStart} | ${'[environment terraform plans][]'} | ${mockTextEnd}
      ${mockTextStart} | ${'[environment terraform plans]'}   | ${mockTextEnd}
    `(
      'should return inline editable, uneditable, and editable tokens in sequence',
      ({ start, middle, end }) => {
        const buildMockTextToken = (content) => ({ type: 'text', tagName: null, content });

        const startToken = buildMockTextToken(start);
        const middleToken = buildMockTextToken(middle);
        const endToken = buildMockTextToken(end);

        const content = `${start}${middle}${end}`;
        const contentToken = buildMockTextToken(content);
        const contentNode = buildMockTextNode(content);
        const context = { origin: jest.fn().mockReturnValueOnce(contentToken) };
        expect(renderer.render(contentNode, context)).toStrictEqual(
          [startToken, buildUneditableInlineTokens(middleToken), endToken].flat(),
        );
      },
    );
  });
});
