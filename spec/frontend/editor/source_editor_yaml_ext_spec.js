import { Document } from 'yaml';
import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import SourceEditor from '~/editor/source_editor';
import { YamlEditorExtension } from '~/editor/extensions/source_editor_yaml_ext';
import { SourceEditorExtension } from '~/editor/extensions/source_editor_extension_base';
import { spyOnApi } from 'jest/editor/helpers';

let baseExtension;
let yamlExtension;

const getEditorInstance = (editorInstanceOptions = {}) => {
  setHTMLFixture('<div id="editor"></div>');
  return new SourceEditor().createInstance({
    el: document.getElementById('editor'),
    blobPath: '.gitlab-ci.yml',
    language: 'yaml',
    ...editorInstanceOptions,
  });
};

const getEditorInstanceWithExtension = (extensionOptions = {}, editorInstanceOptions = {}) => {
  setHTMLFixture('<div id="editor"></div>');
  const instance = getEditorInstance(editorInstanceOptions);
  [baseExtension, yamlExtension] = instance.use([
    { definition: SourceEditorExtension },
    { definition: YamlEditorExtension, setupOptions: extensionOptions },
  ]);

  // Remove the below once
  // https://gitlab.com/gitlab-org/gitlab/-/issues/325992 is resolved
  if (editorInstanceOptions.value && !extensionOptions.model) {
    instance.setValue(editorInstanceOptions.value);
  }

  return instance;
};

describe('YamlCreatorExtension', () => {
  afterEach(() => {
    resetHTMLFixture();
  });

  describe('constructor', () => {
    it('saves setupOptions options on the extension, but does not expose those to instance', () => {
      const highlightPath = 'foo';
      const instance = getEditorInstanceWithExtension({
        highlightPath,
        enableComments: true,
      });
      expect(yamlExtension.obj.highlightPath).toBe(highlightPath);
      expect(yamlExtension.obj.enableComments).toBe(true);
      expect(instance.highlightPath).toBeUndefined();
      expect(instance.enableComments).toBeUndefined();
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
      instance.use({ definition: YamlEditorExtension });
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
      instance.initFromModel(model);
      expect(transformComments).toHaveBeenCalled();
    });

    it('should not call transformComments if enableComments is false', () => {
      const instance = getEditorInstanceWithExtension({ enableComments: false });
      const transformComments = jest.spyOn(YamlEditorExtension, 'transformComments');
      instance.initFromModel(model);
      expect(transformComments).not.toHaveBeenCalled();
    });

    it('should call setValue with the stringified model', () => {
      const instance = getEditorInstanceWithExtension();
      const setValue = jest.spyOn(instance, 'setValue');
      instance.initFromModel(model);
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
      const updateValueSpy = jest.fn();
      spyOnApi(yamlExtension, {
        updateValue: updateValueSpy,
      });
      instance.setDoc(doc);
      expect(setValue).toHaveBeenCalledWith(doc.toString());
      expect(updateValueSpy).not.toHaveBeenCalled();
    });

    it("should call updateValue with the stringified doc if the editor's value is not empty", () => {
      const instance = getEditorInstanceWithExtension({}, { value: 'asjkdhkasjdh' });
      const setValue = jest.spyOn(instance, 'setValue');
      const updateValueSpy = jest.fn();
      spyOnApi(yamlExtension, {
        updateValue: updateValueSpy,
      });
      instance.setDoc(doc);
      expect(setValue).not.toHaveBeenCalled();
      expect(updateValueSpy).toHaveBeenCalledWith(instance, doc.toString());
    });

    it('should trigger the onUpdate method', () => {
      const instance = getEditorInstanceWithExtension();
      const onUpdateSpy = jest.fn();
      spyOnApi(yamlExtension, {
        onUpdate: onUpdateSpy,
      });
      instance.setDoc(doc);
      expect(onUpdateSpy).toHaveBeenCalled();
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
      // Here we do not spy on the public API method of the extension, but rather
      // the public method of the extension's instance.
      // This is required based on how `onUpdate` works
      const highlightSpy = jest.spyOn(yamlExtension.obj, 'highlight');
      instance.onUpdate();
      expect(highlightSpy).toHaveBeenCalledWith(instance, highlightPath);
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
    const value = `foo:
  bar:
    - baz
    - boo
abc: def
`;
    let instance;
    let highlightLinesSpy;
    let removeHighlightsSpy;

    it.each`
      highlightPathOnSetup | path              | keepOnNotFound | expectHighlightLinesToBeCalled | withLines    | expectRemoveHighlightsToBeCalled | storedHighlightPath
      ${null}              | ${undefined}      | ${false}       | ${false}                       | ${undefined} | ${true}                          | ${null}
      ${'abc'}             | ${'abc'}          | ${undefined}   | ${false}                       | ${undefined} | ${false}                         | ${'abc'}
      ${null}              | ${null}           | ${false}       | ${false}                       | ${undefined} | ${false}                         | ${null}
      ${null}              | ${''}             | ${false}       | ${false}                       | ${undefined} | ${true}                          | ${null}
      ${null}              | ${''}             | ${true}        | ${false}                       | ${undefined} | ${true}                          | ${null}
      ${'abc'}             | ${''}             | ${false}       | ${false}                       | ${undefined} | ${true}                          | ${null}
      ${'abc'}             | ${'foo.bar'}      | ${false}       | ${true}                        | ${[2, 4]}    | ${false}                         | ${'foo.bar'}
      ${'abc'}             | ${['foo', 'bar']} | ${false}       | ${true}                        | ${[2, 4]}    | ${false}                         | ${['foo', 'bar']}
      ${'abc'}             | ${'invalid'}      | ${true}        | ${false}                       | ${undefined} | ${false}                         | ${'abc'}
      ${'abc'}             | ${'invalid'}      | ${false}       | ${false}                       | ${undefined} | ${true}                          | ${null}
      ${'abc'}             | ${'invalid'}      | ${undefined}   | ${false}                       | ${undefined} | ${true}                          | ${null}
      ${'abc'}             | ${['invalid']}    | ${undefined}   | ${false}                       | ${undefined} | ${true}                          | ${null}
      ${'abc'}             | ${['invalid']}    | ${true}        | ${false}                       | ${undefined} | ${false}                         | ${'abc'}
      ${'abc'}             | ${[]}             | ${true}        | ${false}                       | ${undefined} | ${true}                          | ${null}
      ${'abc'}             | ${[]}             | ${false}       | ${false}                       | ${undefined} | ${true}                          | ${null}
    `(
      'returns correct result for highlightPathOnSetup=$highlightPathOnSetup, path=$path' +
        ' and keepOnNotFound=$keepOnNotFound',
      ({
        highlightPathOnSetup,
        path,
        keepOnNotFound,
        expectHighlightLinesToBeCalled,
        withLines,
        expectRemoveHighlightsToBeCalled,
        storedHighlightPath,
      }) => {
        instance = getEditorInstanceWithExtension(
          { highlightPath: highlightPathOnSetup },
          { value },
        );

        highlightLinesSpy = jest.fn();
        removeHighlightsSpy = jest.fn();
        spyOnApi(baseExtension, {
          highlightLines: highlightLinesSpy,
          removeHighlights: removeHighlightsSpy,
        });

        instance.highlight(path, keepOnNotFound);

        if (expectHighlightLinesToBeCalled) {
          expect(highlightLinesSpy).toHaveBeenCalledWith(instance, withLines);
        } else {
          expect(highlightLinesSpy).not.toHaveBeenCalled();
        }

        if (expectRemoveHighlightsToBeCalled) {
          expect(removeHighlightsSpy).toHaveBeenCalled();
        } else {
          expect(removeHighlightsSpy).not.toHaveBeenCalled();
        }

        expect(yamlExtension.obj.highlightPath).toEqual(storedHighlightPath);
      },
    );
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

    it('returns [null, null] if a path cannot be found inside the yaml', () => {
      const path = 'baz[8]';
      const instance = getEditorInstanceWithExtension(options);
      expect(instance.locate(path)).toEqual([null, null]);
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
