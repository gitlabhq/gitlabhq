/* eslint-disable no-underscore-dangle */
import { gql, execute, ApolloLink, Observable } from '@apollo/client/core';
import { testApolloLink } from 'helpers/test_apollo_link';
import { getPersistLink } from '~/lib/apollo/persist_link';

const DEFAULT_QUERY = gql`
  query {
    foo {
      bar
    }
  }
`;

const QUERY_WITH_DIRECTIVE = gql`
  query {
    foo @persist {
      bar
    }
  }
`;

const QUERY_WITH_PERSIST_FIELD = gql`
  query {
    foo @persist {
      bar
      __persist
    }
  }
`;

const terminatingLink = new ApolloLink(() => Observable.of({ data: { foo: { bar: 1 } } }));

describe('~/lib/apollo/persist_link', () => {
  let subscription;

  afterEach(() => {
    if (subscription) {
      subscription.unsubscribe();
    }
  });

  it('removes `@persist` directive from the operation', async () => {
    const operation = await testApolloLink(getPersistLink(), {}, QUERY_WITH_DIRECTIVE);
    const { selections } = operation.query.definitions[0].selectionSet;

    expect(selections[0].directives).toEqual([]);
  });

  it('removes `__persist` fields from the operation with `@persist` directive', async () => {
    const operation = await testApolloLink(getPersistLink(), {}, QUERY_WITH_PERSIST_FIELD);

    const { selections } = operation.query.definitions[0].selectionSet;
    const childFields = selections[0].selectionSet.selections;

    expect(childFields).toHaveLength(1);
    expect(childFields.some((field) => field.name.value === '__persist')).toBe(false);
  });

  it('decorates the response with `__persist: true` is there is `__persist` field in the query', () => {
    const link = getPersistLink().concat(terminatingLink);

    subscription = execute(link, { query: QUERY_WITH_PERSIST_FIELD }).subscribe(({ data }) => {
      expect(data.foo.__persist).toBe(true);
    });
  });

  it('does not decorate the response with `__persist: true` is there if query is not persistent', () => {
    const link = getPersistLink().concat(terminatingLink);

    subscription = execute(link, { query: DEFAULT_QUERY }).subscribe(({ data }) => {
      expect(data.foo.__persist).toBe(undefined);
    });
  });
});
