import { Document, parseDocument } from 'yaml';
import { merge } from '~/lib/utils/yaml';

// Mock data for Comments on pairs
const COMMENTS_ON_PAIRS_SOURCE = `foo:
  # barbaz
  bar: baz

  # bazboo
  baz: boo
`;

const COMMENTS_ON_PAIRS_TARGET = `foo:
  # abcdef
  abc: def
  # boobaz
  boo: baz
`;

const COMMENTS_ON_PAIRS_EXPECTED = `foo:
  # abcdef
  abc: def
  # boobaz
  boo: baz
  # barbaz
  bar: baz

  # bazboo
  baz: boo
`;

// Mock data for Comments on seqs
const COMMENTS_ON_SEQS_SOURCE = `foo:
  # barbaz
  - barbaz
  # bazboo
  - baz: boo
`;

const COMMENTS_ON_SEQS_TARGET = `foo:
  # abcdef
  - abcdef

  # boobaz
  - boobaz
`;

const COMMENTS_ON_SEQS_EXPECTED = `foo:
  # abcdef
  - abcdef

  # boobaz
  - boobaz
  # barbaz
  - barbaz
  # bazboo
  - baz: boo
`;

describe('Yaml utility functions', () => {
  describe('merge', () => {
    const getAsNode = (yamlStr) => {
      return parseDocument(yamlStr).contents;
    };

    describe('Merge two Nodes', () => {
      it.each`
        scenario                               | source                                       | target                                         | options                      | expected
        ${'merge a map'}                       | ${getAsNode('foo:\n  bar: baz\n')}           | ${'foo:\n  abc: def\n'}                        | ${undefined}                 | ${'foo:\n  abc: def\n  bar: baz\n'}
        ${'merge a seq'}                       | ${getAsNode('foo:\n  - bar\n')}              | ${'foo:\n  - abc\n'}                           | ${undefined}                 | ${'foo:\n  - bar\n'}
        ${'merge-append seqs'}                 | ${getAsNode('foo:\n  - bar\n')}              | ${'foo:\n  - abc\n'}                           | ${{ onSequence: 'append' }}  | ${'foo:\n  - abc\n  - bar\n'}
        ${'merge-replace a seq'}               | ${getAsNode('foo:\n  - bar\n')}              | ${'foo:\n  - abc\n'}                           | ${{ onSequence: 'replace' }} | ${'foo:\n  - bar\n'}
        ${'override existing paths'}           | ${getAsNode('foo:\n  bar: baz\n')}           | ${'foo:\n  bar: boo\n'}                        | ${undefined}                 | ${'foo:\n  bar: baz\n'}
        ${'deep maps'}                         | ${getAsNode('foo:\n  bar:\n    abc: def\n')} | ${'foo:\n  bar:\n    baz: boo\n  jkl:  mno\n'} | ${undefined}                 | ${'foo:\n  bar:\n    baz: boo\n    abc: def\n  jkl: mno\n'}
        ${'append maps inside seqs'}           | ${getAsNode('foo:\n  - abc: def\n')}         | ${'foo:\n  - bar: baz\n'}                      | ${{ onSequence: 'append' }}  | ${'foo:\n  - bar: baz\n  - abc: def\n'}
        ${'inexistent paths create new nodes'} | ${getAsNode('foo:\n  bar: baz\n')}           | ${'abc: def\n'}                                | ${undefined}                 | ${'abc: def\nfoo:\n  bar: baz\n'}
        ${'document as source'}                | ${parseDocument('foo:\n  bar: baz\n')}       | ${'foo:\n  abc: def\n'}                        | ${undefined}                 | ${'foo:\n  abc: def\n  bar: baz\n'}
        ${'object as source'}                  | ${{ foo: { bar: 'baz' } }}                   | ${'foo:\n  abc: def\n'}                        | ${undefined}                 | ${'foo:\n  abc: def\n  bar: baz\n'}
        ${'comments on pairs'}                 | ${parseDocument(COMMENTS_ON_PAIRS_SOURCE)}   | ${COMMENTS_ON_PAIRS_TARGET}                    | ${undefined}                 | ${COMMENTS_ON_PAIRS_EXPECTED}
        ${'comments on seqs'}                  | ${parseDocument(COMMENTS_ON_SEQS_SOURCE)}    | ${COMMENTS_ON_SEQS_TARGET}                     | ${{ onSequence: 'append' }}  | ${COMMENTS_ON_SEQS_EXPECTED}
      `('$scenario', ({ source, target, expected, options }) => {
        const targetDoc = parseDocument(target);
        merge(targetDoc, source, options);
        const expectedDoc = parseDocument(expected);
        expect(targetDoc.toString()).toEqual(expectedDoc.toString());
      });

      it('type conflict will throw an Error', () => {
        const sourceDoc = parseDocument('foo:\n  bar:\n    - baz\n');
        const targetDoc = parseDocument('foo:\n  bar: def\n');
        expect(() => merge(targetDoc, sourceDoc)).toThrow(
          'Type conflict at "foo.bar": Destination node is of type Scalar, the node' +
            ' to be merged is of type YAMLSeq',
        );
      });

      it('merging a collection into an empty doc', () => {
        const targetDoc = new Document();
        merge(targetDoc, { foo: { bar: 'baz' } });
        const expected = parseDocument('foo:\n  bar: baz\n');
        expect(targetDoc.toString()).toEqual(expected.toString());
      });
    });
  });
});
