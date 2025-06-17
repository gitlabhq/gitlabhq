import { gql } from '@apollo/client/core';

export const mockQueryFactory = (queryName) => {
  return gql`query ${queryName} {
    group(fullPath: "example") {
      id
    }
  }`;
};

export const mockListQueryFactory = (queryName) => {
  return gql`query ${queryName} {
    group(fullPath: "example") {
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
