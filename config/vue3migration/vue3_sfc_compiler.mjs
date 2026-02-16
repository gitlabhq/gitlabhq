/**
 * Custom SFC compiler for Vue 3 migration.
 *
 * This wraps @vue/compiler-sfc and injects our custom template compiler
 * to apply AST transformations needed for Vue 2 compatibility.
 *
 * Used by @vitejs/plugin-vue when VUE_VERSION=3.
 */

import * as defaultCompiler from '@vue/compiler-sfc';
import vue3TemplateCompiler from './vue3_template_compiler.js';

export * from '@vue/compiler-sfc';

export function compileTemplate(options) {
  return defaultCompiler.compileTemplate({
    ...options,
    compiler: vue3TemplateCompiler,
  });
}
