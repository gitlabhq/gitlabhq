// eslint-disable-next-line import/prefer-default-export
export const createVuexContext = createState => {
  const commit = jest.fn();
  const dispatch = jest.fn(() => Promise.resolve());
  const state = createState();
  return { commit, dispatch, state };
};
