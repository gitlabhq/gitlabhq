import { observable } from '~/lib/utils/observable';

export const hashState = observable('blob_hash_state', {
  currentHash: window.location.hash,
});

export const updateHash = (newHash) => {
  hashState.currentHash = newHash;
};
