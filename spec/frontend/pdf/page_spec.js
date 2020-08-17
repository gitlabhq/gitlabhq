import Vue from 'vue';
import mountComponent from 'helpers/vue_mount_component_helper';
import PageComponent from '~/pdf/page/index.vue';

jest.mock('pdfjs-dist/webpack', () => {
  return { default: jest.requireActual('pdfjs-dist/build/pdf') };
});

describe('Page component', () => {
  const Component = Vue.extend(PageComponent);
  let vm;

  afterEach(() => {
    vm.$destroy();
  });

  it('renders the page when mounting', done => {
    const promise = Promise.resolve();
    const testPage = {
      render: jest.fn().mockReturnValue({ promise: Promise.resolve() }),
      getViewport: jest.fn().mockReturnValue({}),
    };

    vm = mountComponent(Component, {
      page: testPage,
      number: 1,
    });

    expect(vm.rendering).toBe(true);

    promise
      .then(() => {
        expect(testPage.render).toHaveBeenCalledWith(vm.renderContext);
        expect(vm.rendering).toBe(false);
      })
      .then(done)
      .catch(done.fail);
  });
});
