import { REST, GRAPHQL } from './constants';

export const accessors = {
  [REST]: {
    groupId: 'id',
  },
  [GRAPHQL]: {
    groupId: 'name',
  },
};
