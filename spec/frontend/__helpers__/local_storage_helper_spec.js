import { useLocalStorageSpy } from './local_storage_helper';

afterEach(() => {
  if (jest.isMockFunction(localStorage.setItem)) {
    throw new Error('Helper did not correctly restore original localStorage implementation');
  }
});

describe('block before helper is installed', () => {
  it('should leave original localStorage intact', () => {
    expect(localStorage.getItem).toEqual(expect.any(Function));
    expect(jest.isMockFunction(localStorage.getItem)).toBe(false);
  });
});

describe('localStorage helper', () => {
  useLocalStorageSpy();

  it('mocks localStorage but works exactly like original localStorage', () => {
    localStorage.setItem('test', 'testing');
    localStorage.setItem('test2', 'testing');

    expect(localStorage.getItem('test')).toBe('testing');

    localStorage.removeItem('test', 'testing');

    expect(localStorage.getItem('test')).toBe(null);
    expect(localStorage.getItem('test2')).toBe('testing');

    localStorage.clear();

    expect(localStorage.getItem('test2')).toBe(null);
  });
});

describe('in multiple describe blocks', () => {
  describe('first', () => {
    useLocalStorageSpy();

    it('works', () => {
      expect(jest.isMockFunction(localStorage.setItem)).toBe(true);
    });
  });

  describe('second', () => {
    useLocalStorageSpy();

    it('also works', () => {
      expect(jest.isMockFunction(localStorage.setItem)).toBe(true);
    });
  });
});

describe('nested calls', () => {
  useLocalStorageSpy();

  describe('...', () => {
    useLocalStorageSpy();

    it('also still work', () => {
      expect(jest.isMockFunction(localStorage.setItem)).toBe(true);
    });
  });
});
