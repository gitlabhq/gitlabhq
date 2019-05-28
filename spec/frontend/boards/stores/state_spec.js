import createState from '~/boards/stores/state';

describe('createState', () => {
  it('is a function', () => {
    expect(createState).toEqual(expect.any(Function));
  });

  it('returns an object', () => {
    expect(createState()).toEqual(expect.any(Object));
  });
});
