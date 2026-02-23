const vueTemplateCompiler = require('vue-template-compiler');
const { parse } = require('@babel/parser');
const generate = require('@babel/generator').default;
const t = require('@babel/types');

// Vue 3 compiler automatically adds keys to v-if/v-else/v-else-if branches (key:0, key:1, etc.)
// to prevent Vue from reusing component/element instances between branches. Vue 2 compiler
// doesn't do this, which can cause issues when branches have different directives - Vue tries
// to patch the element but the directive arrays have different lengths, causing errors like
// "Cannot read properties of undefined (reading 'value')" in invokeDirectiveHook.
//
// This module injects numeric keys into v-if/v-else chains that don't already have user-defined keys,
// matching Vue 3 compiler behavior. Keys are only added when all branches have the same tag name,
// since Vue can already differentiate elements with different tags.
//
// Unlike the regex-based approach, this uses @babel/parser to parse the generated code as a proper
// AST and injects the key property by manipulating AST nodes, making it robust against any code
// formatting variations.
/* eslint-disable no-underscore-dangle, no-param-reassign */

function getAstRoot(el) {
  let node = el;
  while (node.parent) {
    node = node.parent;
  }
  return node;
}

function getNextChainId(el) {
  const root = getAstRoot(el);
  if (root._vIfChainCounter === undefined) {
    root._vIfChainCounter = 0;
  }
  root._vIfChainCounter += 1;
  return root._vIfChainCounter;
}

function injectKeyViaAST(code, keyValue) {
  const ast = parse(code, { sourceType: 'module' });
  const expr = ast.program.body[0].expression;

  if (!t.isCallExpression(expr) || expr.arguments.length === 0) return code;

  const { arguments: args } = expr;
  const keyProp = t.objectProperty(t.identifier('key'), t.stringLiteral(keyValue));

  if (args.length >= 2 && t.isObjectExpression(args[1])) {
    args[1].properties.unshift(keyProp);
  } else if (args.length >= 2 && t.isCallExpression(args[1])) {
    let innerCall = args[1];
    while (t.isCallExpression(innerCall.arguments[0])) {
      [innerCall] = innerCall.arguments;
    }
    if (t.isObjectExpression(innerCall.arguments[0])) {
      innerCall.arguments[0].properties.unshift(keyProp);
    }
  } else {
    args.splice(1, 0, t.objectExpression([keyProp]));
  }

  return generate(ast, { compact: true }).code.replace(/;$/, '');
}

function shouldInjectKeys(ifConditions) {
  if (ifConditions.some((c) => c.block.key)) return false;

  const firstTag = ifConditions[0].block.tag;
  return ifConditions.every((c) => c.block.tag === firstTag);
}

function findVIfRoot(el) {
  if (el._vIfRoot) return el._vIfRoot;

  if (el.parent) {
    for (const sibling of el.parent.children || []) {
      if (sibling.ifConditions) {
        const idx = sibling.ifConditions.findIndex((c) => c.block === el);
        if (idx !== -1) return sibling;
      }
    }
  }

  return null;
}

const addVIfKeysModule = {
  transformCode(el, code) {
    if (el.key) return code;

    if (el.if && el.ifConditions && el.ifConditions.length > 1) {
      if (!shouldInjectKeys(el.ifConditions)) return code;

      const chainId = getNextChainId(el);
      el._vIfChainId = chainId;

      el.ifConditions.forEach((c, idx) => {
        c.block._vIfRoot = el;
        c.block._vIfBranchIndex = idx;
      });

      return injectKeyViaAST(code, `_vif_${chainId}_0`);
    }

    if (el.else || el.elseif) {
      const vIfRoot = findVIfRoot(el);
      if (!vIfRoot || !shouldInjectKeys(vIfRoot.ifConditions)) return code;

      const idx = el._vIfBranchIndex ?? vIfRoot.ifConditions.findIndex((c) => c.block === el);
      if (idx === -1) return code;

      return injectKeyViaAST(code, `_vif_${vIfRoot._vIfChainId}_${idx}`);
    }

    return code;
  },
};

/* eslint-enable no-underscore-dangle, no-param-reassign */

function mergeModules(options) {
  const existingModules = options?.modules || [];
  return {
    ...options,
    modules: [...existingModules, addVIfKeysModule],
  };
}

module.exports = {
  compile(template, options) {
    return vueTemplateCompiler.compile(template, mergeModules(options));
  },
  compileToFunctions(template, options) {
    return vueTemplateCompiler.compileToFunctions(template, mergeModules(options));
  },
  ssrCompile(template, options) {
    return vueTemplateCompiler.ssrCompile(template, mergeModules(options));
  },
  ssrCompileToFunctions(template, options) {
    return vueTemplateCompiler.ssrCompileToFunctions(template, mergeModules(options));
  },
  parseComponent: vueTemplateCompiler.parseComponent,
  generateCodeFrame: vueTemplateCompiler.generateCodeFrame,
};
