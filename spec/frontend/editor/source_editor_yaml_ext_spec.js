import { Document } from 'yaml';
import SourceEditor from '~/editor/source_editor';
import { YamlEditorExtension } from '~/editor/extensions/source_editor_yaml_ext';
import { SourceEditorExtension } from '~/editor/extensions/source_editor_extension_base';

const getEditorInstance = (editorInstanceOptions = {}) => {
  setFixtures('<div id="editor"></div>');
  return new SourceEditor().createInstance({
    el: document.getElementById('editor'),
    blobPath: '.gitlab-ci.yml',
    language: 'yaml',
    ...editorInstanceOptions,
  });
};

const getEditorInstanceWithExtension = (extensionOptions = {}, editorInstanceOptions = {}) => {
  setFixtures('<div id="editor"></div>');
  const instance = getEditorInstance(editorInstanceOptions);
  instance.use(new YamlEditorExtension({ instance, ...extensionOptions }));

  // Remove the below once
  // https://gitlab.com/gitlab-org/gitlab/-/issues/325992 is resolved
  if (editorInstanceOptions.value && !extensionOptions.model) {
    instance.setValue(editorInstanceOptions.value);
  }

  return instance;
};

describe('YamlCreatorExtension', () => {
  describe('constructor', () => {
    it('saves constructor options', () => {
      const instance = getEditorInstanceWithExtension({
        highlightPath: 'foo',
        enableComments: true,
      });
      expect(instance).toEqual(
        expect.objectContaining({
          options: expect.objectContaining({
            highlightPath: 'foo',
            enableComments: true,
          }),
        }),
      );
    });

    it('dumps values loaded with the model constructor options', () => {
      const model = { foo: 'bar' };
      const expected = 'foo: bar\n';
      const instance = getEditorInstanceWithExtension({ model });
      expect(instance.getDoc().get('foo')).toBeDefined();
      expect(instance.getValue()).toEqual(expected);
    });

    it('registers the onUpdate() function', () => {
      const instance = getEditorInstance();
      const onDidChangeModelContent = jest.spyOn(instance, 'onDidChangeModelContent');
      instance.use(new YamlEditorExtension({ instance }));
      expect(onDidChangeModelContent).toHaveBeenCalledWith(expect.any(Function));
    });

    it("If not provided with a load constructor option, it will parse the editor's value", () => {
      const editorValue = 'foo: bar';
      const instance = getEditorInstanceWithExtension({}, { value: editorValue });
      expect(instance.getDoc().get('foo')).toBeDefined();
    });

    it("Prefers values loaded with the load constructor option over the editor's existing value", () => {
      const editorValue = 'oldValue: this should be overriden';
      const model = { thisShould: 'be the actual value' };
      const expected = 'thisShould: be the actual value\n';
      const instance = getEditorInstanceWithExtension({ model }, { value: editorValue });
      expect(instance.getDoc().get('oldValue')).toBeUndefined();
      expect(instance.getValue()).toEqual(expected);
    });
  });

  describe('initFromModel', () => {
    const model = { foo: 'bar', 1: 2, abc: ['def'] };
    const doc = new Document(model);

    it('should call transformComments if enableComments is true', () => {
      const instance = getEditorInstanceWithExtension({ enableComments: true });
      const transformComments = jest.spyOn(YamlEditorExtension, 'transformComments');
      YamlEditorExtension.initFromModel(instance, model);
      expect(transformComments).toHaveBeenCalled();
    });

    it('should not call transformComments if enableComments is false', () => {
      const instance = getEditorInstanceWithExtension({ enableComments: false });
      const transformComments = jest.spyOn(YamlEditorExtension, 'transformComments');
      YamlEditorExtension.initFromModel(instance, model);
      expect(transformComments).not.toHaveBeenCalled();
    });

    it('should call setValue with the stringified model', () => {
      const instance = getEditorInstanceWithExtension();
      const setValue = jest.spyOn(instance, 'setValue');
      YamlEditorExtension.initFromModel(instance, model);
      expect(setValue).toHaveBeenCalledWith(doc.toString());
    });
  });

  describe('wrapCommentString', () => {
    const longString =
      'Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua. At vero eos et accusam et justo duo dolores et ea rebum. Stet clita kasd gubergren, no sea takimata sanctus est Lorem ipsum dolor sit amet. Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua. At vero eos et accusam et justo duo dolores et ea rebum. Stet clita kasd gubergren, no sea takimata sanctus est Lorem ipsum dolor sit amet.';

    it('should add spaces before each line', () => {
      const result = YamlEditorExtension.wrapCommentString(longString);
      const lines = result.split('\n');
      expect(lines.every((ln) => ln.startsWith(' '))).toBe(true);
    });

    it('should break long comments into lines of max. 79 chars', () => {
      // 79 = 80 char width minus 1 char for the '#' at the start of each line
      const result = YamlEditorExtension.wrapCommentString(longString);
      const lines = result.split('\n');
      expect(lines.every((ln) => ln.length <= 79)).toBe(true);
    });

    it('should decrease the line width if passed a level by 2 chars per level', () => {
      for (let i = 0; i <= 5; i += 1) {
        const result = YamlEditorExtension.wrapCommentString(longString, i);
        const lines = result.split('\n');
        const decreaseLineWidthBy = i * 2;
        const maxLineWith = 79 - decreaseLineWidthBy;
        const isValidLine = (ln) => {
          if (ln.length <= maxLineWith) return true;
          // The line may exceed the max line width in case the word is the
          // only one in the line and thus cannot be broken further
          return ln.split(' ').length <= 1;
        };
        expect(lines.every(isValidLine)).toBe(true);
      }
    });

    it('return null if passed an invalid string value', () => {
      expect(YamlEditorExtension.wrapCommentString(null)).toBe(null);
      expect(YamlEditorExtension.wrapCommentString()).toBe(null);
    });

    it('throw an error if passed an invalid level value', () => {
      expect(() => YamlEditorExtension.wrapCommentString('abc', -5)).toThrow(
        'Invalid value "-5" for variable `level`',
      );
      expect(() => YamlEditorExtension.wrapCommentString('abc', 'invalid')).toThrow(
        'Invalid value "invalid" for variable `level`',
      );
    });
  });

  describe('transformComments', () => {
    const getInstanceWithModel = (model) => {
      return getEditorInstanceWithExtension({
        model,
        enableComments: true,
      });
    };

    it('converts comments inside an array', () => {
      const model = ['# test comment', 'def', '# foo', 999];
      const expected = `# test comment\n- def\n# foo\n- 999\n`;
      const instance = getInstanceWithModel(model);
      expect(instance.getValue()).toEqual(expected);
    });

    it('converts generic comments inside an object and places them at the top', () => {
      const model = { foo: 'bar', 1: 2, '#': 'test comment' };
      const expected = `# test comment\n"1": 2\nfoo: bar\n`;
      const instance = getInstanceWithModel(model);
      expect(instance.getValue()).toEqual(expected);
    });

    it('adds specific comments before the mentioned entry of an object', () => {
      const model = { foo: 'bar', 1: 2, '#|foo': 'foo comment' };
      const expected = `"1": 2\n# foo comment\nfoo: bar\n`;
      const instance = getInstanceWithModel(model);
      expect(instance.getValue()).toEqual(expected);
    });

    it('limits long comments to 80 char width, including indentation', () => {
      const model = {
        '#|foo':
          'Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua. At vero eos et accusam et justo duo dolores et ea rebum.',
        foo: {
          nested1: {
            nested2: {
              nested3: {
                '#|bar':
                  'Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua. At vero eos et accusam et justo duo dolores et ea rebum.',
                bar: 'baz',
              },
            },
          },
        },
      };
      const expected = `# Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy
# eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam
# voluptua. At vero eos et accusam et justo duo dolores et ea rebum.
foo:
  nested1:
    nested2:
      nested3:
        # Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam
        # nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat,
        # sed diam voluptua. At vero eos et accusam et justo duo dolores et ea
        # rebum.
        bar: baz
`;
      const instance = getInstanceWithModel(model);
      expect(instance.getValue()).toEqual(expected);
    });
  });

  describe('getDoc', () => {
    it('returns a yaml `Document` Type', () => {
      const instance = getEditorInstanceWithExtension();
      expect(instance.getDoc()).toBeInstanceOf(Document);
    });
  });

  describe('setDoc', () => {
    const model = { foo: 'bar', 1: 2, abc: ['def'] };
    const doc = new Document(model);

    it('should call transformComments if enableComments is true', () => {
      const spy = jest.spyOn(YamlEditorExtension, 'transformComments');
      const instance = getEditorInstanceWithExtension({ enableComments: true });
      instance.setDoc(doc);
      expect(spy).toHaveBeenCalledWith(doc);
    });

    it('should not call transformComments if enableComments is false', () => {
      const spy = jest.spyOn(YamlEditorExtension, 'transformComments');
      const instance = getEditorInstanceWithExtension({ enableComments: false });
      instance.setDoc(doc);
      expect(spy).not.toHaveBeenCalled();
    });

    it("should call setValue with the stringified doc if the editor's value is empty", () => {
      const instance = getEditorInstanceWithExtension();
      const setValue = jest.spyOn(instance, 'setValue');
      const updateValue = jest.spyOn(instance, 'updateValue');
      instance.setDoc(doc);
      expect(setValue).toHaveBeenCalledWith(doc.toString());
      expect(updateValue).not.toHaveBeenCalled();
    });

    it("should call updateValue with the stringified doc if the editor's value is not empty", () => {
      const instance = getEditorInstanceWithExtension({}, { value: 'asjkdhkasjdh' });
      const setValue = jest.spyOn(instance, 'setValue');
      const updateValue = jest.spyOn(instance, 'updateValue');
      instance.setDoc(doc);
      expect(setValue).not.toHaveBeenCalled();
      expect(updateValue).toHaveBeenCalledWith(doc.toString());
    });

    it('should trigger the onUpdate method', () => {
      const instance = getEditorInstanceWithExtension();
      const onUpdate = jest.spyOn(instance, 'onUpdate');
      instance.setDoc(doc);
      expect(onUpdate).toHaveBeenCalled();
    });
  });

  describe('getDataModel', () => {
    it('returns the model as JS', () => {
      const value = 'abc: def\nfoo:\n  - bar\n  - baz\n';
      const expected = { abc: 'def', foo: ['bar', 'baz'] };
      const instance = getEditorInstanceWithExtension({}, { value });
      expect(instance.getDataModel()).toEqual(expected);
    });
  });

  describe('setDataModel', () => {
    it('sets the value to a YAML-representation of the Doc', () => {
      const model = {
        abc: ['def'],
        '#|foo': 'foo comment',
        foo: {
          '#|abc': 'abc comment',
          abc: [{ def: 'ghl', lorem: 'ipsum' }, '# array comment', null],
          bar: 'baz',
        },
      };
      const expected =
        'abc:\n' +
        '  - def\n' +
        '# foo comment\n' +
        'foo:\n' +
        '  # abc comment\n' +
        '  abc:\n' +
        '    - def: ghl\n' +
        '      lorem: ipsum\n' +
        '    # array comment\n' +
        '    - null\n' +
        '  bar: baz\n';

      const instance = getEditorInstanceWithExtension({ enableComments: true });
      const setValue = jest.spyOn(instance, 'setValue');

      instance.setDataModel(model);

      expect(setValue).toHaveBeenCalledWith(expected);
    });

    it('causes the editor value to be updated', () => {
      const initialModel = { foo: 'this should be overriden' };
      const initialValue = 'foo: this should be overriden\n';
      const newValue = { thisShould: 'be the actual value' };
      const expected = 'thisShould: be the actual value\n';
      const instance = getEditorInstanceWithExtension({ model: initialModel });
      expect(instance.getValue()).toEqual(initialValue);
      instance.setDataModel(newValue);
      expect(instance.getValue()).toEqual(expected);
    });
  });

  describe('onUpdate', () => {
    it('calls highlight', () => {
      const highlightPath = 'foo';
      const instance = getEditorInstanceWithExtension({ highlightPath });
      instance.highlight = jest.fn();
      instance.onUpdate();
      expect(instance.highlight).toHaveBeenCalledWith(highlightPath);
    });
  });

  describe('updateValue', () => {
    it("causes the editor's value to be updated", () => {
      const oldValue = 'foobar';
      const newValue = 'bazboo';
      const instance = getEditorInstanceWithExtension({}, { value: oldValue });
      instance.updateValue(newValue);
      expect(instance.getValue()).toEqual(newValue);
    });
  });

  describe('highlight', () => {
    const highlightPathOnSetup = 'abc';
    const value = `foo:
  bar:
    - baz
    - boo
  abc: def
`;
    let instance;
    let highlightLinesSpy;
    let removeHighlightsSpy;

    beforeEach(() => {
      instance = getEditorInstanceWithExtension({ highlightPath: highlightPathOnSetup }, { value });
      highlightLinesSpy = jest.spyOn(SourceEditorExtension, 'highlightLines');
      removeHighlightsSpy = jest.spyOn(SourceEditorExtension, 'removeHighlights');
    });

    afterEach(() => {
      jest.clearAllMocks();
    });

    it('saves the highlighted path in highlightPath', () => {
      const path = 'foo.bar';
      instance.highlight(path);
      expect(instance.options.highlightPath).toEqual(path);
    });

    it('calls highlightLines with a number of lines', () => {
      const path = 'foo.bar';
      instance.highlight(path);
      expect(highlightLinesSpy).toHaveBeenCalledWith(instance, [2, 4]);
    });

    it('calls removeHighlights if path is null', () => {
      instance.highlight(null);
      expect(removeHighlightsSpy).toHaveBeenCalledWith(instance);
      expect(highlightLinesSpy).not.toHaveBeenCalled();
      expect(instance.options.highlightPath).toBeNull();
    });

    it('throws an error if path is invalid and does not change the highlighted path', () => {
      expect(() => instance.highlight('invalidPath[0]')).toThrow(
        'The node invalidPath[0] could not be found inside the document.',
      );
      expect(instance.options.highlightPath).toEqual(highlightPathOnSetup);
      expect(highlightLinesSpy).not.toHaveBeenCalled();
      expect(removeHighlightsSpy).not.toHaveBeenCalled();
    });
  });

  describe('locate', () => {
    const options = {
      enableComments: true,
      model: {
        abc: ['def'],
        '#|foo': 'foo comment',
        foo: {
          '#|abc': 'abc comment',
          abc: [{ def: 'ghl', lorem: 'ipsum' }, '# array comment', null],
          bar: 'baz',
        },
      },
    };

    const value =
      /*  1 */ 'abc:\n' +
      /*  2 */ '  - def\n' +
      /*  3 */ '# foo comment\n' +
      /*  4 */ 'foo:\n' +
      /*  5 */ '  # abc comment\n' +
      /*  6 */ '  abc:\n' +
      /*  7 */ '    - def: ghl\n' +
      /*  8 */ '      lorem: ipsum\n' +
      /*  9 */ '    # array comment\n' +
      /* 10 */ '    - null\n' +
      /* 11 */ '  bar: baz\n';

    it('asserts that the test setup is correct', () => {
      const instance = getEditorInstanceWithExtension(options);
      expect(instance.getValue()).toEqual(value);
    });

    it('returns the expected line numbers for a path to an object inside the yaml', () => {
      const path = 'foo.abc';
      const expected = [6, 10];
      const instance = getEditorInstanceWithExtension(options);
      expect(instance.locate(path)).toEqual(expected);
    });

    it('throws an error if a path cannot be found inside the yaml', () => {
      const path = 'baz[8]';
      const instance = getEditorInstanceWithExtension(options);
      expect(() => instance.locate(path)).toThrow();
    });

    it('returns the expected line numbers for a path to an array entry inside the yaml', () => {
      const path = 'foo.abc[0]';
      const expected = [7, 8];
      const instance = getEditorInstanceWithExtension(options);
      expect(instance.locate(path)).toEqual(expected);
    });

    it('returns the expected line numbers for a path that includes a comment inside the yaml', () => {
      const path = 'foo';
      const expected = [4, 11];
      const instance = getEditorInstanceWithExtension(options);
      expect(instance.locate(path)).toEqual(expected);
    });
  });
});
