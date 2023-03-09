import toast from '~/vue_shared/plugins/global_toast';

const mockSpy = jest.fn();
jest.mock('@gitlab/ui', () => ({
  GlToast: (Vue) => {
    // eslint-disable-next-line no-param-reassign
    Vue.prototype.$toast = { show: (...args) => mockSpy(...args) };
  },
}));

describe('Global toast', () => {
  afterEach(() => {
    mockSpy.mockRestore();
  });

  it("should call GitLab UI's toast method", () => {
    const arg1 = 'TestMessage';
    const arg2 = { className: 'foo' };

    toast(arg1, arg2);

    expect(mockSpy).toHaveBeenCalledTimes(1);
    expect(mockSpy).toHaveBeenCalledWith(arg1, arg2);
  });
});
