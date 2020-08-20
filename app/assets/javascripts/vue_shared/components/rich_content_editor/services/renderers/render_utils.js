import {
  buildUneditableBlockTokens,
  buildUneditableOpenTokens,
  buildUneditableCloseToken,
} from './build_uneditable_token';

export const renderUneditableLeaf = (_, { origin }) => buildUneditableBlockTokens(origin());

export const renderUneditableBranch = (_, { entering, origin }) =>
  entering ? buildUneditableOpenTokens(origin()) : buildUneditableCloseToken();
