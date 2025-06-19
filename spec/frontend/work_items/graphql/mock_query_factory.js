import { gql } from '@apollo/client/core';

export const mockQueryFactory = (queryName) => {
  return gql`query ${queryName} {
    namespace(fullPath: "example") {
      id
    }
  }`;
};

export const mockListQueryFactory = (queryName) => {
  return gql`query ${queryName} {
    namespace(fullPath: "example") {
      id
      workItems {
        nodes {
          id
          widgets
        }
      }
    }
  }`;
};
