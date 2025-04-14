import { parseFields } from '~/glql/core/parser/fields';
import * as ast from '~/glql/core/parser/ast';

describe('GLQL Fields Parser', () => {
  describe('parseFields', () => {
    it('parses a single field name', () => {
      const result = parseFields('title');
      expect(result).toEqual(ast.collection(ast.fieldName('title')));
    });

    it('parses multiple field names', () => {
      const result = parseFields('title,description,createdAt');
      expect(result).toEqual(
        ast.collection(
          ast.fieldName('title'),
          ast.fieldName('description'),
          ast.fieldName('createdAt'),
        ),
      );
    });

    it('parses a function call', () => {
      const result = parseFields('labels("bug")');
      expect(result).toEqual(
        ast.collection(ast.functionCall('labels', ast.collection(ast.string('bug')))),
      );
    });

    it('parses a function call with multiple arguments', () => {
      const result = parseFields('labels("bug", "feature")');
      expect(result).toEqual(
        ast.collection(
          ast.functionCall('labels', ast.collection(ast.string('bug'), ast.string('feature'))),
        ),
      );
    });

    it('parses a mix of field names and function calls', () => {
      const result = parseFields('title,labels("bug"),description');
      expect(result).toEqual(
        ast.collection(
          ast.fieldName('title'),
          ast.functionCall('labels', ast.collection(ast.string('bug'))),
          ast.fieldName('description'),
        ),
      );
    });

    it('handles whitespace', () => {
      const result = parseFields(' title , labels( "bug" ) , description ');
      expect(result).toEqual(
        ast.collection(
          ast.fieldName('title'),
          ast.functionCall('labels', ast.collection(ast.string('bug'))),
          ast.fieldName('description'),
        ),
      );
    });

    it('handles aliases correctly', () => {
      const result = parseFields('title as "t", labels("bug") as "l", description as "d"');
      expect(result).toEqual(
        ast.collection(
          ast.fieldName('title').withAlias(ast.string('t')),
          ast.functionCall('labels', ast.collection(ast.string('bug'))).withAlias(ast.string('l')),
          ast.fieldName('description').withAlias(ast.string('d')),
        ),
      );
    });

    it('parses AS token for aliases in a case-insesitive manner', () => {
      const result = parseFields('title As "t", description, createdAt AS "c"');
      expect(result).toEqual(
        ast.collection(
          ast.fieldName('title').withAlias(ast.string('t')),
          ast.fieldName('description'),
          ast.fieldName('createdAt').withAlias(ast.string('c')),
        ),
      );
    });

    it('handles aliases with whitespace', () => {
      const result = parseFields(
        ' title  as  "t" , labels( "bug" )  as     "l" ,   description as  "d"  ',
      );
      expect(result).toEqual(
        ast.collection(
          ast.fieldName('title').withAlias(ast.string('t')),
          ast.functionCall('labels', ast.collection(ast.string('bug'))).withAlias(ast.string('l')),
          ast.fieldName('description').withAlias(ast.string('d')),
        ),
      );
    });

    it('throws an error for invalid input', () => {
      expect(() => parseFields('title,')).toThrow('Parse error');
    });

    it('throws an error for unclosed function call', () => {
      expect(() => parseFields('labels("bug"')).toThrow('Parse error');
    });
  });
});
