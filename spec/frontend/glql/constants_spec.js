import { DISPLAY_TYPES, PAGINATION_BY_DISPLAY_TYPE } from '~/glql/constants';

describe('GLQL constants', () => {
  it('assigns a pagination strategy to every display type', () => {
    expect(Object.keys(PAGINATION_BY_DISPLAY_TYPE).sort()).toEqual(
      Object.values(DISPLAY_TYPES).sort(),
    );
  });
});
