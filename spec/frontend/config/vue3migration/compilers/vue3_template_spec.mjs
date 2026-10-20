import { describe, it, expect, vi } from 'vitest';
import { compileTemplate, parse as parseSfc } from '@vue/compiler-sfc';
import vue3Template from '../../../../../config/vue3migration/compilers/vue3_template';

describe('vue3_template compiler', () => {
  // vue-loader and @vue/vue3-jest call the compiler through compileTemplate.
  describe('through compileTemplate', () => {
    const template = '<div><my-component /></div>';
    const compileTemplateWith = (compiler, extra = {}) =>
      compileTemplate({ id: 'test', filename: 'test.vue', source: template, compiler, ...extra });

    it('produces the same code as the default compiler', () => {
      const ours = compileTemplateWith(vue3Template);
      const upstream = compileTemplateWith(undefined);

      expect(ours.errors).toEqual([]);
      expect(ours.code).toBe(upstream.code);
    });

    // So compile() never gets an AST that the SFC descriptor still uses.
    it('passes the source string, not the descriptor AST', () => {
      const compile = vi.spyOn(vue3Template, 'compile');
      const { descriptor } = parseSfc(`<template>${template}</template>`);

      compileTemplateWith(vue3Template, { ast: descriptor.template.ast });

      expect(compile).toHaveBeenCalledWith(template, expect.any(Object));
      compile.mockRestore();
    });
  });

  describe('with a key on the children of a v-for', () => {
    const compileSource = (source) =>
      compileTemplate({ id: 'test', filename: 'test.vue', source, compiler: vue3Template });

    // Vue 2 allows this, but Vue 3 fails with X_V_FOR_TEMPLATE_KEY_PLACEMENT.
    it('moves the key from the children of <template v-for> to the <template>', () => {
      const { code, errors } = compileSource(
        '<div><template v-for="item in items"><span :key="item.id" /></template></div>',
      );

      expect(errors).toEqual([]);
      expect(code).toContain('key: item.id');
    });

    it('keeps the key on the child of an element with v-for', () => {
      const { code } = compileSource(
        '<div><div v-for="item in items" :key="item.id"><my-component :key="item.version" /></div></div>',
      );

      expect(code).toContain('key: item.id');
      expect(code).toContain('key: item.version');
    });
  });

  describe('with isCustomElement in the options', () => {
    it('uses the isCustomElement from the options', () => {
      const { code } = vue3Template.compile('<div><gl-emoji /><my-element /></div>', {
        mode: 'module',
        isCustomElement: (tag) => tag === 'my-element',
      });

      expect(code).toContain('"my-element"');
      expect(code).toContain('resolveComponent("gl-emoji")');
    });
  });

  // thread-loader drops the isCustomElement function from the webpack loader options,
  // so the compiler must apply its own list when the options have none.
  describe('without isCustomElement in the options', () => {
    const template = '<div><gl-emoji data-name="thumbsup" /></div>';

    it('compiles a custom element as an element', () => {
      const { code } = vue3Template.compile(template, { mode: 'module' });

      expect(code).not.toContain('resolveComponent');
      expect(code).toContain('"gl-emoji"');
    });
  });
});
