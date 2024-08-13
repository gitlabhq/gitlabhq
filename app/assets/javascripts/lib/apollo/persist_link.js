// this file is based on https://github.com/apollographql/apollo-cache-persist/blob/master/examples/react-native/src/utils/persistence/persistLink.ts
// with some heavy refactororing

/* eslint-disable consistent-return */
/* eslint-disable @gitlab/require-i18n-strings */
/* eslint-disable no-param-reassign */
import { visit } from 'graphql';
import { ApolloLink } from '@apollo/client/core';
import traverse from 'traverse';

const extractPersistDirectivePaths = (originalQuery, directive = 'persist') => {
  const paths = [];
  const fragmentPaths = {};
  const fragmentPersistPaths = {};

  const query = visit(originalQuery, {
    // eslint-disable-next-line max-params
    FragmentSpread: ({ name: { value: name } }, _key, _parent, _path, ancestors) => {
      const root = ancestors.find(
        ({ kind }) => kind === 'OperationDefinition' || kind === 'FragmentDefinition',
      );

      const rootKey = root.kind === 'FragmentDefinition' ? root.name.value : '$ROOT';

      const fieldPath = ancestors
        .filter(({ kind }) => kind === 'Field')
        .map(({ name: { value } }) => value);

      fragmentPaths[name] = [rootKey].concat(fieldPath);
    },
    // eslint-disable-next-line max-params
    Directive: ({ name: { value: name } }, _key, _parent, _path, ancestors) => {
      if (name === directive) {
        const fieldPath = ancestors
          .filter(({ kind }) => kind === 'Field')
          .map(({ name: { value } }) => value);

        const fragmentDefinition = ancestors.find(({ kind }) => kind === 'FragmentDefinition');

        // If we are inside a fragment, we must save the reference.
        if (fragmentDefinition) {
          fragmentPersistPaths[fragmentDefinition.name.value] = fieldPath;
        } else if (fieldPath.length) {
          paths.push(fieldPath);
        }
        return null;
      }
    },
  });

  // In case there are any FragmentDefinition items, we need to combine paths.
  if (Object.keys(fragmentPersistPaths).length) {
    visit(originalQuery, {
      // eslint-disable-next-line max-params
      FragmentSpread: ({ name: { value: name } }, _key, _parent, _path, ancestors) => {
        if (fragmentPersistPaths[name]) {
          let fieldPath = ancestors
            .filter(({ kind }) => kind === 'Field')
            .map(({ name: { value } }) => value);

          fieldPath = fieldPath.concat(fragmentPersistPaths[name]);

          const fragment = name;
          let parent = fragmentPaths[fragment][0];

          while (parent && parent !== '$ROOT' && fragmentPaths[parent]) {
            fieldPath = fragmentPaths[parent].slice(1).concat(fieldPath);
            // eslint-disable-next-line prefer-destructuring
            parent = fragmentPaths[parent][0];
          }

          paths.push(fieldPath);
        }
      },
    });
  }

  return { query, paths };
};

/**
 * Given a data result object path, return the equivalent query selection path.
 *
 * @param {Array} path The data result object path. i.e.: ["a", 0, "b"]
 * @return {String} the query selection path. i.e.: "a.b"
 */
const toQueryPath = (path) => path.filter((key) => Number.isNaN(Number(key))).join('.');

const attachPersists = (paths, object) => {
  const queryPaths = paths.map(toQueryPath);
  function mapperFunction() {
    if (
      !this.isRoot &&
      this.node &&
      typeof this.node === 'object' &&
      Object.keys(this.node).length &&
      !Array.isArray(this.node)
    ) {
      const path = toQueryPath(this.path);

      this.update({
        __persist: Boolean(
          queryPaths.find(
            (queryPath) => queryPath.indexOf(path) === 0 || path.indexOf(queryPath) === 0,
          ),
        ),
        ...this.node,
      });
    }
  }

  return traverse(object).map(mapperFunction);
};

export const getPersistLink = () => {
  return new ApolloLink((operation, forward) => {
    const { query, paths } = extractPersistDirectivePaths(operation.query);

    // Noop if not a persist query
    if (!paths.length) {
      return forward(operation);
    }

    // Replace query with one without @persist directives.
    operation.query = query;

    // Remove requesting __persist fields.
    operation.query = visit(operation.query, {
      Field: ({ name: { value: name } }) => {
        if (name === '__persist') {
          return null;
        }
      },
    });

    return forward(operation).map((result) => {
      if (result.data) {
        result.data = attachPersists(paths, result.data);
      }

      return result;
    });
  });
};
