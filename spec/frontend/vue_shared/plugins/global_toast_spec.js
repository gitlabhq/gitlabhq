import Vue from 'vue';
import toast from '~/vue_shared/plugins/global_toast';

describe('Global toast', () => {
  let spyFunc;

  beforeEach(() => {
    spyFunc = jest.spyOn(Vue.prototype.$toast, 'show').mockImplementation(() => {});
  });

  afterEach(() => {
    spyFunc.mockRestore();
  });

  it("should call GitLab UI's toast method", () => {
    const arg1 = 'TestMessage';
    const arg2 = { className: 'foo' };

    toast(arg1, arg2);

    expect(Vue.prototype.$toast.show).toHaveBeenCalledTimes(1);
    expect(Vue.prototype.$toast.show).toHaveBeenCalledWith(arg1, arg2);
  });
});
