import { useLocalStorageSpy } from './local_storage_helper';

useLocalStorageSpy();

describe('localStorage helper', () => {
  it('mocks localStorage but works exactly like original localStorage', () => {
    localStorage.setItem('test', 'testing');
    localStorage.setItem('test2', 'testing');

    expect(localStorage.getItem('test')).toBe('testing');

    localStorage.removeItem('test', 'testing');

    expect(localStorage.getItem('test')).toBeUndefined();
    expect(localStorage.getItem('test2')).toBe('testing');

    localStorage.clear();

    expect(localStorage.getItem('test2')).toBeUndefined();
  });
});
