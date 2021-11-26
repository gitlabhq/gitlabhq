import getList from '~/packages_and_registries/infrastructure_registry/list/stores/getters';
import { packageList } from '../../mock_data';

describe('Getters registry list store', () => {
  let state;

  const setState = ({ isGroupPage = false } = {}) => {
    state = {
      packages: packageList,
      config: {
        isGroupPage,
      },
    };
  };

  beforeEach(() => setState());

  afterEach(() => {
    state = null;
  });

  describe('getList', () => {
    it('returns a list of packages', () => {
      const result = getList(state);

      expect(result).toHaveLength(packageList.length);
      expect(result[0].name).toBe('Test package');
    });

    it('adds projectPathName', () => {
      const result = getList(state);

      expect(result[0].projectPathName).toMatchInlineSnapshot(`"foo / bar / baz"`);
    });
  });
});
