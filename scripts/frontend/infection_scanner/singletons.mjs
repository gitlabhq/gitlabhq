import { parse } from '@babel/parser';

// Only top-level statements count: a call inside a function is a factory.

export const SINGLETON_CALLEES = [
  { id: 'pinia-store', callee: 'defineStore' },
  { id: 'pinia-instance', callee: 'createPinia' },
  { id: 'apollo-client', callee: 'ApolloClient' },
  { id: 'apollo-reactive-var', callee: 'makeVar' },
  { id: 'event-hub', callee: 'createEventHub' },
  { id: 'event-hub', callee: 'mitt' },
  { id: 'vuex-store', callee: 'Vuex.Store' },
  { id: 'vue-observable', callee: 'Vue.observable' },
  { id: 'define-property', callee: 'Object.defineProperty' },
];

// Matched on the import because `~/lib/graphql`'s default export has many local names.
// `VueApollo` is excluded: a provider is bound to its Vue version.
export const SINGLETON_IMPORTS = [
  { id: 'apollo-client', path: 'lib/graphql', imported: 'default' },
  { id: 'apollo-client', path: 'lib/customers_dot_graphql', imported: 'createCustomersDotClient' },
];

const ID_BY_CALLEE = new Map(SINGLETON_CALLEES.map(({ id, callee }) => [callee, id]));

// Cheap pre-filter before the parse.
const NEEDLES = [
  ...new Set([
    ...SINGLETON_CALLEES.map(({ callee }) => callee.split('.').pop()),
    ...SINGLETON_IMPORTS.map(({ path: modulePath }) => modulePath),
  ]),
];

const PARSE_OPTIONS = { sourceType: 'unambiguous', errorRecovery: true, plugins: ['jsx'] };

const calleeName = (node) => {
  if (node?.type === 'Identifier') return node.name;
  if (node?.type === 'MemberExpression' && node.property?.type === 'Identifier') {
    const object = node.object?.type === 'Identifier' ? node.object.name : null;
    return object && `${object}.${node.property.name}`;
  }
  return null;
};

const singletonIdOf = (node, idByBinding) => {
  if (node?.type !== 'CallExpression' && node?.type !== 'NewExpression') return null;
  const name = calleeName(node.callee);
  return ID_BY_CALLEE.get(name) ?? idByBinding.get(name) ?? null;
};

const bindingsOf = (body) => {
  const idByBinding = new Map();

  for (const statement of body) {
    if (statement.type !== 'ImportDeclaration') continue;

    for (const rule of SINGLETON_IMPORTS) {
      if (!statement.source.value.endsWith(rule.path)) continue;

      for (const specifier of statement.specifiers) {
        const imported =
          specifier.type === 'ImportDefaultSpecifier' ? 'default' : specifier.imported?.name;
        if (imported === rule.imported) idByBinding.set(specifier.local.name, rule.id);
      }
    }
  }
  return idByBinding;
};

const topLevelExpressions = (node) => {
  switch (node.type) {
    case 'VariableDeclaration':
      return node.declarations.map((declaration) => declaration.init);
    case 'ExportNamedDeclaration':
      return node.declaration ? topLevelExpressions(node.declaration) : [];
    case 'ExportDefaultDeclaration':
      return [node.declaration];
    case 'ExpressionStatement':
      return node.expression?.type === 'AssignmentExpression'
        ? [node.expression.right]
        : [node.expression];
    default:
      return [];
  }
};

export function detectSingletons(code) {
  if (!code || !NEEDLES.some((needle) => code.includes(needle))) return [];

  let ast;
  try {
    ast = parse(code, PARSE_OPTIONS);
  } catch {
    return [];
  }

  const idByBinding = bindingsOf(ast.program.body);
  const found = new Set();
  for (const statement of ast.program.body) {
    for (const expression of topLevelExpressions(statement)) {
      const id = singletonIdOf(expression, idByBinding);
      if (id) found.add(id);
    }
  }
  return [...found];
}
